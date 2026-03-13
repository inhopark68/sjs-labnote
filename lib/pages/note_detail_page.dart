import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:labnote/controllers/note_editor_controller.dart';
import 'package:labnote/controllers/note_image_controller.dart';
import 'package:labnote/controllers/note_items_controller.dart';

import 'package:labnote/data/database/app_database.dart';
import 'package:labnote/utils/note_delete_utils.dart';
import 'package:labnote/utils/ocr_utils.dart';
import 'package:labnote/utils/quill_doc_utils.dart';

import 'package:labnote/widgets/note_attachment_preview.dart';
import 'package:labnote/widgets/note_body_section.dart';
import 'package:labnote/widgets/note_date_card.dart';
import 'package:labnote/widgets/note_materials_section.dart';
import 'package:labnote/widgets/note_reagents_section.dart';
import 'package:labnote/widgets/note_references_section.dart';
import 'package:labnote/widgets/note_title_section.dart';

import 'package:labnote/utils/pick_date_time.dart';
import 'package:labnote/features/figures/add_to_figure_dialog.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteId;

  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage>
    with WidgetsBindingObserver {
  AppDatabase get _db => context.read<AppDatabase>();

  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _bodyQuill = quill.QuillController.basic();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();

  final ScrollController _bodyScroll = ScrollController();

  final ImagePicker _picker = ImagePicker();

  late final NoteEditorController _editor;
  late final NoteImageController _imageController;
  late final NoteItemsController _itemsController;

  bool _noteLoading = true;
  bool _itemsLoading = true;
  bool _noteIsDeleted = false;

  DateTime? _selectedNoteDate;
  Note? _note;

  int? _selectedAttachmentId;
  late Future<List<NoteAttachmentRow>> _attachmentsFuture;

  bool get _ocrSupported => !kIsWeb;

  @override
  void initState() {
    super.initState();

    _editor = NoteEditorController(
      db: _db,
      noteId: widget.noteId,
      titleTextGetter: () => _titleController.text,
      bodyQuill: _bodyQuill,
      noteImagePrefixBuilder: _noteImagePrefix,
    );

    _imageController = NoteImageController(
      db: _db,
      noteId: widget.noteId,
      picker: _picker,
    );

    _itemsController = NoteItemsController(
      db: _db,
      noteId: widget.noteId,
      newIdBuilder: _newId,
    );

    _attachmentsFuture = _db.listNoteAttachments(widget.noteId);

    WidgetsBinding.instance.addObserver(this);

    _titleController.addListener(_onTitleChanged);
    _bodyQuill.addListener(_onBodyChanged);

    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _editor.dispose();

    _titleController.removeListener(_onTitleChanged);
    _bodyQuill.removeListener(_onBodyChanged);

    _titleController.dispose();
    _bodyQuill.dispose();

    _titleFocus.dispose();
    _bodyFocus.dispose();

    _bodyScroll.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _editor.cancelDebounce();
      _saveIfNeeded(force: true);
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _noteLoading = true;
      _itemsLoading = true;
    });

    final results = await Future.wait([
      _db.getNoteAny(widget.noteId),
      _itemsController.loadAll(),
      _db.listNoteAttachments(widget.noteId),
    ]);

    final noteAny = results[0] as Note?;
    final attachments = results[2] as List<NoteAttachmentRow>;
    final isDeleted = noteAny?.isDeleted ?? true;

    if (!mounted) return;

    _note = noteAny;
    _noteIsDeleted = isDeleted;
    _selectedNoteDate = noteAny?.noteDate;

    _editor.suppressEditorListener = true;
    try {
      _titleController.text = _decodeTitleToPlainText(noteAny?.title);
      decodeDocOrPlainText(_bodyQuill, noteAny?.body);
      _editor.dirty = false;
      _editor.lastSavedAt = null;
    } finally {
      _editor.suppressEditorListener = false;
    }

    final stillExists = attachments.any((e) => e.id == _selectedAttachmentId);
    if (!stillExists) {
      _selectedAttachmentId = null;
    }

    setState(() {
      _noteLoading = false;
      _itemsLoading = false;
      _attachmentsFuture = Future.value(attachments);
    });
  }

  Future<void> _refresh() => _loadAll();

  void _onTitleChanged() {
    if (_editor.suppressEditorListener || _noteIsDeleted) return;
    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  void _onBodyChanged() {
    if (_editor.suppressEditorListener || _noteIsDeleted) return;

    final before = _imageController.selectedBodyImagePath;
    _imageController.syncBodySelectionFromDoc(_bodyQuill);
    final after = _imageController.selectedBodyImagePath;

    if (before != after && mounted) {
      setState(() {});
    }

    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  void _markDirtyAndDebounceSave({required bool triggerRebuild}) {
    _editor.markDirty();

    if (triggerRebuild && mounted) {
      setState(() {});
    }

    _editor.markDirtyAndDebounceSave(
      onBeforeSave: () async {
        if (!mounted) return;
        setState(() {});
      },
      onAfterSave: () async {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Future<void> _saveIfNeeded({bool force = false}) async {
    if (_noteIsDeleted) return;

    try {
      await _editor.saveIfNeeded(
        force: force,
        onBeforeSave: () async {
          if (!mounted) return;
          setState(() {});
        },
        onAfterSave: () async {
          if (!mounted) return;
          setState(() {});
        },
      );
    } catch (e) {
      _editor.dirty = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          action: SnackBarAction(
            label: '재시도',
            onPressed: () => _saveIfNeeded(force: true),
          ),
        ),
      );
    }
  }

  Future<void> _reloadAttachments() async {
    final attachments = await _db.listNoteAttachments(widget.noteId);

    if (!mounted) return;

    final stillExists = attachments.any((e) => e.id == _selectedAttachmentId);

    setState(() {
      if (!stillExists) {
        _selectedAttachmentId = null;
      }
      _attachmentsFuture = Future.value(attachments);
    });
  }

  NoteAttachmentRow? _findSelectedAttachment(List<NoteAttachmentRow> items) {
    for (final item in items) {
      if (item.id == _selectedAttachmentId) return item;
    }
    return null;
  }

  String _noteImagePrefix() => 'img_';

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _decodeTitleToPlainText(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(
          List<Map<String, dynamic>>.from(decoded),
        );
        return doc.toPlainText().replaceAll('\n', ' ').trim();
      }
    } catch (_) {}

    return raw.replaceAll('\n', ' ').trim();
  }

  void _blockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제된 노트는 수정할 수 없습니다. 복원 후 수정하세요.')),
    );
  }

  void _ocrNotSupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR은 모바일(Android/iOS)에서만 지원됩니다.')),
    );
  }

  void _imageNotSupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 삽입은 모바일(Android/iOS)에서만 지원됩니다.')),
    );
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String okText,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okText),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _moveToTrash() async {
    final ok = await _confirmDialog(
      title: '휴지통으로 이동',
      message: '이 노트를 휴지통으로 이동할까요?\n(완전 삭제가 아니며, 복원할 수 있습니다.)',
      okText: '이동',
    );
    if (!ok) return;

    try {
      _editor.cancelDebounce();
      await _saveIfNeeded(force: true);
      await _db.deleteNote(widget.noteId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴지통으로 이동했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이동 실패: $e')),
      );
    }
  }

  Future<void> _restoreFromTrash() async {
    final ok = await _confirmDialog(
      title: '복원',
      message: '이 노트를 복원할까요?',
      okText: '복원',
    );
    if (!ok) return;

    try {
      await _db.restoreNote(widget.noteId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트를 복원했습니다.')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복원 실패: $e')),
      );
    }
  }

  Future<void> _confirmHardDelete() async {
    final ok = await _confirmDialog(
      title: '완전 삭제',
      message:
          '이 노트를 완전히 삭제할까요?\n노트에 연결된 시약/재료/DOI 기록도 함께 삭제되며, 복구할 수 없습니다.',
      okText: '완전 삭제',
    );
    if (!ok) return;

    try {
      _editor.cancelDebounce();
      await hardDeleteNoteWithAssets(
        db: _db,
        noteId: widget.noteId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트를 완전 삭제했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('완전 삭제 실패: $e')),
      );
    }
  }

  Future<String?> _runOcrAndReturnText() async {
    if (!_ocrSupported) {
      _ocrNotSupportedSnack();
      return null;
    }
    if (_noteIsDeleted) {
      _blockedSnack();
      return null;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final raw = await extractTextWithMlKit(picked.path);
    final text = normalizeOcrText(raw);

    if (text.trim().isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR 결과가 비어 있습니다. 더 선명한 이미지로 다시 시도해 주세요.'),
        ),
      );
      return null;
    }

    return text;
  }

  Future<void> _pickNoteDate() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final initial = _selectedNoteDate ?? _note?.noteDate ?? DateTime.now();

    final picked = await pickDateTime(
      context,
      initialDateTime: initial,
    );

    if (picked == null) return;

    try {
      await _db.updateNoteDate(widget.noteId, picked);

      if (!mounted) return;
      setState(() {
        _selectedNoteDate = picked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트 날짜를 저장했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('날짜 저장 실패: $e')),
      );
    }
  }

  Future<void> _clearNoteDate() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    try {
      await _db.updateNoteDate(widget.noteId, null);

      if (!mounted) return;
      setState(() => _selectedNoteDate = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트 날짜를 제거했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('날짜 제거 실패: $e')),
      );
    }
  }

  String _currentTitleForAppBar() {
    final t = _titleController.text.trim();
    return t.isEmpty ? '(제목 없음)' : t;
  }

  String _formatSavedTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _saveStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    if (_editor.saving) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('저장중…'),
            ],
          ),
        ),
      );
    }

    if (_noteIsDeleted) {
      return const SizedBox.shrink();
    }

    if (_editor.dirty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          backgroundColor: theme.colorScheme.primaryContainer,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('●', style: TextStyle(color: theme.colorScheme.primary)),
              const SizedBox(width: 8),
              const Text('저장 필요'),
            ],
          ),
        ),
      );
    }

    final savedLabel = _editor.lastSavedAt == null
        ? '저장됨'
        : '${_formatSavedTime(_editor.lastSavedAt!)} 저장됨';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 16),
            const SizedBox(width: 6),
            Text(savedLabel),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddToFigureDialog(NoteAttachmentRow attachment) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddToFigureDialog(
        noteId: widget.noteId,
        attachmentId: attachment.id,
        initialTitle: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
      ),
    );

    if (!mounted) return;

    if (added == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Figure에 추가했습니다.')),
      );
    }
  }

  Widget _buildFigureAttachSection() {
    return FutureBuilder<List<NoteAttachmentRow>>(
      future: _attachmentsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <NoteAttachmentRow>[];
        final imageItems = items.where((e) => e.kind == 'image').toList();
        final selectedAttachment = _findSelectedAttachment(imageItems);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (imageItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Figure로 추가',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...imageItems.map((attachment) {
                  final isSelected = _selectedAttachmentId == attachment.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedAttachmentId =
                              _selectedAttachmentId == attachment.id
                                  ? null
                                  : attachment.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildNoteAttachmentPreview(
                              filePath: attachment.filePath,
                              width: 72,
                              height: 72,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.basename(attachment.filePath),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.check_circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'attachment id: ${attachment.id}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: (_noteIsDeleted || selectedAttachment == null)
                        ? null
                        : () => _openAddToFigureDialog(selectedAttachment),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('선택한 이미지 Figure에 추가'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_noteLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope<bool>(
      canPop: !_editor.saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        try {
          _editor.cancelDebounce();
          await _saveIfNeeded(force: true);
        } catch (_) {}
        if (!mounted) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitleForAppBar()),
          actions: [
            _saveStatusChip(context),
            TextButton.icon(
              onPressed: (_noteIsDeleted || _editor.saving)
                  ? null
                  : () => _saveIfNeeded(force: true),
              icon: const Icon(Icons.save),
              label: const Text('저장'),
            ),
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'trash':
                    _moveToTrash();
                    break;
                  case 'restore':
                    _restoreFromTrash();
                    break;
                  case 'hard_delete':
                    _confirmHardDelete();
                    break;
                }
              },
              itemBuilder: (context) {
                if (_noteIsDeleted) {
                  return const [
                    PopupMenuItem(value: 'restore', child: Text('복원')),
                    PopupMenuItem(value: 'hard_delete', child: Text('완전 삭제')),
                  ];
                }
                return const [
                  PopupMenuItem(value: 'trash', child: Text('휴지통으로 이동')),
                  PopupMenuItem(value: 'hard_delete', child: Text('완전 삭제')),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (_noteIsDeleted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '이 노트는 삭제 상태입니다. 복원하면 제목/내용과 시약/재료/DOI를 다시 수정할 수 있습니다.',
                      ),
                    ),
                  ),
                ),
              NoteDateCard(
                noteDate: _selectedNoteDate,
                onPickDate: _pickNoteDate,
                onClearDate: _selectedNoteDate != null ? _clearNoteDate : null,
              ),
              const SizedBox(height: 8),
              NoteTitleSection(
                controller: _titleController,
                focusNode: _titleFocus,
                enabled: !_noteIsDeleted,
                ocrSupported: _ocrSupported,
                runOcrAndReturnText: _runOcrAndReturnText,
              ),
              const SizedBox(height: 12),
              NoteBodySection(
                controller: _bodyQuill,
                focusNode: _bodyFocus,
                scrollController: _bodyScroll,
                enabled: !_noteIsDeleted,
                embedBuilders: _imageController.buildEmbedBuilders(
                  controller: _bodyQuill,
                  onChanged: () {
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
                onInsertImage: () async {
                  if (_noteIsDeleted) {
                    _blockedSnack();
                    return;
                  }

                  if (!_imageController.imageInsertSupported) {
                    _imageNotSupportedSnack();
                    return;
                  }

                  final inserted = await _imageController.insertImageInto(
                    context: context,
                    controller: _bodyQuill,
                    focusNode: _bodyFocus,
                    filePrefix: _noteImagePrefix(),
                    onChanged: () {
                      if (!mounted) return;
                      setState(() {});
                    },
                  );

                  if (inserted) {
                    await _reloadAttachments();
                    _markDirtyAndDebounceSave(triggerRebuild: true);
                  }
                },
                onDeleteImage: _imageController.selectedBodyImagePath == null
                    ? null
                    : () async {
                        if (_noteIsDeleted) {
                          _blockedSnack();
                          return;
                        }

                        final deleted =
                            await _imageController.deleteSelectedBodyImage(
                          context: context,
                          bodyQuill: _bodyQuill,
                          onChanged: () {
                            if (!mounted) return;
                            setState(() {});
                          },
                        );

                        if (deleted) {
                          await _reloadAttachments();
                          _markDirtyAndDebounceSave(triggerRebuild: true);
                        }
                      },
              ),
              const SizedBox(height: 16),
              _buildFigureAttachSection(),
              const SizedBox(height: 16),
              const Divider(height: 32),
              if (_itemsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                NoteReagentsSection(
                  reagents: _itemsController.reagents,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted
                      ? _blockedSnack
                      : () async {
                          final added = await _itemsController.addReagent(
                            context: context,
                            enableOcr: _ocrSupported,
                            onRequestOcrText: _runOcrAndReturnText,
                          );
                          if (!mounted || !added) return;
                          setState(() {});
                        },
                  onDelete: (id) async {
                    if (_noteIsDeleted) {
                      _blockedSnack();
                      return;
                    }
                    await _itemsController.deleteReagent(id);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
                NoteMaterialsSection(
                  materials: _itemsController.materials,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted
                      ? _blockedSnack
                      : () async {
                          final added = await _itemsController.addMaterial(
                            context: context,
                            enableOcr: _ocrSupported,
                            onRequestOcrText: _runOcrAndReturnText,
                          );
                          if (!mounted || !added) return;
                          setState(() {});
                        },
                  onDelete: (id) async {
                    if (_noteIsDeleted) {
                      _blockedSnack();
                      return;
                    }
                    await _itemsController.deleteMaterial(id);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
                NoteReferencesSection(
                  references: _itemsController.references,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted
                      ? _blockedSnack
                      : () async {
                          final added = await _itemsController.addReference(
                            context: context,
                            enableOcr: _ocrSupported,
                            onRequestOcrText: _runOcrAndReturnText,
                          );
                          if (!mounted || !added) return;
                          setState(() {});
                        },
                  onDelete: (id) async {
                    if (_noteIsDeleted) {
                      _blockedSnack();
                      return;
                    }
                    await _itemsController.deleteReference(id);
                    if (!mounted) return;
                    setState(() {});
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}