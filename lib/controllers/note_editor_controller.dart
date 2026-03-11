import 'dart:async';

import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:labnote/data/app_database.dart';
import 'package:labnote/utils/quill_doc_utils.dart';

class NoteEditorController {
  NoteEditorController({
    required this.db,
    required this.noteId,
    required this.titleTextGetter,
    required this.bodyQuill,
    required this.noteImagePrefixBuilder,
  });

  final AppDatabase db;
  final int noteId;
  final String Function() titleTextGetter;
  final quill.QuillController bodyQuill;
  final String Function() noteImagePrefixBuilder;

  bool suppressEditorListener = false;
  bool dirty = false;
  bool saving = false;
  DateTime? lastSavedAt;

  Timer? _debounce;

  void markDirty() {
    dirty = true;
  }

  void cancelDebounce() {
    _debounce?.cancel();
    _debounce = null;
  }

  void markDirtyAndDebounceSave({
    Future<void> Function()? onBeforeSave,
    Future<void> Function()? onAfterSave,
  }) {
    dirty = true;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      await saveIfNeeded(
        onBeforeSave: onBeforeSave,
        onAfterSave: onAfterSave,
      );
    });
  }

  Future<void> saveIfNeeded({
    bool force = false,
    Future<void> Function()? onBeforeSave,
    Future<void> Function()? onAfterSave,
  }) async {
    if (saving) return;
    if (!force && !dirty) return;

    saving = true;
    await onBeforeSave?.call();

    try {
      final title = titleTextGetter();
      final body = encodeDoc(bodyQuill);

      await db.updateNoteContent(
        noteId,
        title: title,
        body: body,
      );

      dirty = false;
      lastSavedAt = DateTime.now();
    } finally {
      saving = false;
      await onAfterSave?.call();
    }
  }

  void dispose() {
    cancelDebounce();
  }
}