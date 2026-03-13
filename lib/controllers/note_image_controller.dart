import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:labnote/data/database/app_database.dart';
import 'package:labnote/utils/note_image_utils.dart';
import 'package:labnote/utils/quill_doc_utils.dart';

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

class _PreparedImageResult {
  final File file;
  final String mimeType;
  final int width;
  final int height;

  const _PreparedImageResult({
    required this.file,
    required this.mimeType,
    required this.width,
    required this.height,
  });
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

  bool _shouldKeepAsPng(File inputFile) {
    final ext = p.extension(inputFile.path).toLowerCase();
    return ext == '.png';
  }

  Future<_PreparedImageResult> _prepareImageForFigureUpload({
    required File inputFile,
    required Directory outputDir,
    required String filePrefix,
    int maxWidth = 1200,
    int jpegQuality = 88,
  }) async {
    final rawBytes = await inputFile.readAsBytes();
    final decoded = img.decodeImage(rawBytes);

    if (decoded == null) {
      throw Exception('이미지를 읽을 수 없습니다.');
    }

    final baked = img.bakeOrientation(decoded);

    img.Image output = baked;
    if (baked.width > maxWidth) {
      output = img.copyResize(
        baked,
        width: maxWidth,
        interpolation: img.Interpolation.average,
      );
    }

    final keepPng = _shouldKeepAsPng(inputFile);

    late final Uint8List encodedBytes;
    late final String extension;
    late final String mimeType;

    if (keepPng) {
      encodedBytes = Uint8List.fromList(img.encodePng(output));
      extension = '.png';
      mimeType = 'image/png';
    } else {
      encodedBytes = Uint8List.fromList(
        img.encodeJpg(output, quality: jpegQuality),
      );
      extension = '.jpg';
      mimeType = 'image/jpeg';
    }

    final fileName =
        '${filePrefix}${DateTime.now().millisecondsSinceEpoch}$extension';
    final outputPath = p.join(outputDir.path, fileName);

    final outFile = File(outputPath);
    await outFile.writeAsBytes(encodedBytes, flush: true);

    return _PreparedImageResult(
      file: outFile,
      mimeType: mimeType,
      width: output.width,
      height: output.height,
    );
  }

  Future<void> _showProcessingDialog(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text('이미지 최적화 중…'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeProcessingDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
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

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return false;

    await _showProcessingDialog(context);

    try {
      final inputFile = File(picked.path);
      final dir = await noteImageDir(noteId);

      final prepared = await _prepareImageForFigureUpload(
        inputFile: inputFile,
        outputDir: dir,
        filePrefix: filePrefix,
        maxWidth: 1200,
        jpegQuality: 88,
      );

      await db.insertNoteAttachment(
        noteId: noteId,
        filePath: prepared.file.path,
        mimeType: prepared.mimeType,
        kind: 'image',
      );

      final embedPath = normalizeImageRef(prepared.file.path);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 처리 실패: $e')),
      );
      return false;
    } finally {
      _closeProcessingDialog(context);
    }
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