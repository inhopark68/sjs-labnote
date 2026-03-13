import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

import 'package:labnote/data/database/app_database.dart';
import 'package:labnote/utils/image_utils.dart';
import 'package:labnote/utils/note_image_utils.dart';
import 'package:labnote/utils/quill_doc_utils.dart';
import 'package:labnote/features/figures/add_to_figure_dialog.dart';

class SelectableImageEmbedBuilder implements quill.EmbedBuilder {
  final quill.EmbedBuilder baseBuilder;
  final Future<void> Function(String imagePath) onTapImage;

  const SelectableImageEmbedBuilder({
    required this.baseBuilder,
    required this.onTapImage,
  });

  @override
  String get key => 'image';

  @override
  bool get expanded => baseBuilder.expanded;

  @override
  String toPlainText(quill.Embed node) => baseBuilder.toPlainText(node);

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return baseBuilder.buildWidgetSpan(widget);
  }

  @override
  Widget build(
    BuildContext context,
    quill.EmbedContext embedContext,
  ) {
    final node = embedContext.node;
    final imagePath = node.value.data.toString();
    final child = baseBuilder.build(context, embedContext);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapImage(imagePath),
      child: child,
    );
  }
}

class NoteImageController {
  final AppDatabase db;
  final int noteId;
  final ImagePicker picker;

  String? selectedBodyImagePath;

  NoteImageController({
    required this.db,
    required this.noteId,
    required this.picker,
  });

  bool get imageInsertSupported => !kIsWeb;

  List<quill.EmbedBuilder> buildEmbedBuilders({
    required quill.QuillController controller,
    required VoidCallback onChanged,
  }) {
    final baseBuilders = kIsWeb
        ? FlutterQuillEmbeds.editorWebBuilders()
        : FlutterQuillEmbeds.editorBuilders();

    return baseBuilders.map<quill.EmbedBuilder>((builder) {
      if (builder.key == 'image') {
        return SelectableImageEmbedBuilder(
          baseBuilder: builder,
          onTapImage: (imagePath) async {
            selectedBodyImagePath = normalizeImageRef(imagePath);
            onChanged();
          },
        );
      }
      return builder;
    }).toList();
  }

  int? findImageEmbedOffsetByPath(
    quill.QuillController controller,
    String imagePath,
  ) {
    final target = normalizeImageRef(imagePath);
    final delta = controller.document.toDelta().toList();

    int offset = 0;

    for (final op in delta) {
      final data = op.data;

      if (data is String) {
        offset += data.length;
        continue;
      }

      if (data is Map && data['image'] is String) {
        final current = normalizeImageRef(data['image'] as String);
        if (current == target) {
          return offset;
        }
        offset += 1;
        continue;
      }

      offset += 1;
    }

    return null;
  }

  void syncBodySelectionFromDoc(quill.QuillController bodyQuill) {
    final refs = extractImagePathsFromDoc(bodyQuill)
        .map(normalizeImageRef)
        .toSet();

    if (selectedBodyImagePath != null &&
        !refs.contains(normalizeImageRef(selectedBodyImagePath!))) {
      selectedBodyImagePath = null;
    }
  }

  Future<ImageSource?> pickSourceSheet(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('이미지 폴더'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> askMaxSizeMb(BuildContext context) {
    final ctrl = TextEditingController(text: '1.0');

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미지 용량 제한'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '최대 MB (예: 1.0)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }

  Future<bool> insertImageInto({
    required BuildContext context,
    required quill.QuillController controller,
    required FocusNode focusNode,
    required String filePrefix,
    required VoidCallback onChanged,
  }) async {
    if (!imageInsertSupported) return false;

    FocusScope.of(context).requestFocus(focusNode);
    await Future.delayed(const Duration(milliseconds: 10));

    final source = await pickSourceSheet(context);
    if (source == null) return false;

    final maxMb = await askMaxSizeMb(context);
    if (maxMb == null) return false;

    final picked = await picker.pickImage(source: source);
    if (picked == null) return false;

    final inputFile = File(picked.path);
    final dir = await noteImageDir(noteId);

    final outFile = await compressImageToTargetMb(
      inputFile: inputFile,
      targetMb: maxMb,
      outputDir: dir,
      filePrefix: filePrefix,
    );

    await db.insertNoteAttachment(
      noteId: noteId,
      filePath: outFile.path,
      mimeType: 'image/*',
      kind: 'image',
    );

    final embedPath = normalizeImageRef(outFile.path);
    final embed = quill.BlockEmbed.image(embedPath);

    final docLength = controller.document.length;
    final baseOffset = controller.selection.baseOffset;

    final index = (baseOffset >= 0 && baseOffset < docLength)
        ? baseOffset
        : max(0, docLength - 1);

    controller.replaceText(
      index,
      0,
      embed,
      TextSelection.collapsed(offset: index + 1),
    );

    selectedBodyImagePath = embedPath;
    onChanged();
    return true;
  }

  Future<bool> deleteSelectedBodyImage({
    required BuildContext context,
    required quill.QuillController bodyQuill,
    required VoidCallback onChanged,
  }) async {
    final selectedPath = selectedBodyImagePath;

    if (selectedPath == null || selectedPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 삭제할 이미지를 선택해 주세요.')),
      );
      return false;
    }

    final imageOffset = findImageEmbedOffsetByPath(bodyQuill, selectedPath);
    if (imageOffset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지를 문서에서 찾지 못했습니다.')),
      );
      selectedBodyImagePath = null;
      onChanged();
      return false;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('선택한 이미지를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok != true) return false;

    bodyQuill.replaceText(
      imageOffset,
      1,
      '',
      TextSelection.collapsed(offset: max(0, imageOffset)),
    );

    selectedBodyImagePath = null;
    onChanged();
    return true;
  }
}