import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../dao/note_dao.dart';
import '../../services/attachment_storage.dart';
import '../../services/image_compressor.dart';
import '../../repositories/reagent_repository_drift.dart';
import '../capture/ocr_label_sheet.dart';
import '../../models/attachment.dart';

// ✅ Windows 카메라 페이지
import '../camera/camera_capture_page.dart';

class NoteSheetVm extends ChangeNotifier {
  final NoteDao dao;
  final AttachmentStorage storage;
  final ImageCompressor compressor;
  final ReagentRepositoryDrift reagentRepo;

  final _picker = ImagePicker();

  String? noteId;

  bool loading = false;
  bool saving = false;
  bool isLocked = false;

  final List<Attachment> attachments = [];

  NoteSheetVm(this.dao, this.storage, this.compressor, this.reagentRepo);

  Future<void> init({String? noteId}) async {
    this.noteId = noteId;
    notifyListeners();
  }

  bool get canEdit => !isLocked && !loading && !saving;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> addPhotoFromCamera(BuildContext context) async {
    if (!canEdit) return;
    await _ensureNoteExists();

    // ✅ Windows: camera_windows(=camera 플러그인)로 촬영 화면 사용
    if (_isWindows) {
      final Uint8List? bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const CameraCapturePage()),
      );
      if (bytes == null) return;

      await _saveBytesAsAttachment(bytes, caption: null);
      return;
    }

    // ✅ 모바일: image_picker 카메라 사용
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (x == null) return;

    final rawBytes = await x.readAsBytes();
    await _saveBytesAsAttachment(rawBytes, caption: null);
  }

  Future<void> addPhotoFromGallery() async {
    if (!canEdit) return;
    await _ensureNoteExists();

    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    final rawBytes = await x.readAsBytes();
    await _saveBytesAsAttachment(rawBytes, caption: null);
  }

  Future<void> _saveBytesAsAttachment(
    Uint8List rawBytes, {
    String? caption,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final id = noteId!;
      final jpeg = await compressor.compressToJpegBytes(rawBytes);

      final savedPath = await storage.saveCompressedJpegToAttachments(
        noteId: id,
        jpegBytes: jpeg ?? rawBytes,
      );

      final now = DateTime.now();
      attachments.add(
        Attachment(
          id: now.microsecondsSinceEpoch.toString(),
          noteId: id,
          type: 'photo',
          path: savedPath,
          caption: caption,
          createdAt: now,
        ),
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAttachmentById(String attachmentId) async {
    if (!canEdit) return;
    attachments.removeWhere((a) => a.id == attachmentId);
    notifyListeners();
  }

  Future<void> openOcrLabelFlowContinuous(BuildContext context) async {
    if (!canEdit) return;
    await _ensureNoteExists();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => OcrLabelSheet(
        continuousMode: true,
        onSubmit: (ocr) async {
          await _processOcrResult(ocr);
        },
      ),
    );
  }

  Future<void> _processOcrResult(OcrReagentResult ocr) async {
    loading = true;
    notifyListeners();
    try {
      final id = noteId!;
      final jpeg = await compressor.compressToJpegBytes(ocr.rawPhotoBytes);

      final savedPath = await storage.saveCompressedJpegToAttachments(
        noteId: id,
        jpegBytes: jpeg ?? ocr.rawPhotoBytes,
      );

      final now = DateTime.now();
      attachments.add(
        Attachment(
          id: now.microsecondsSinceEpoch.toString(),
          noteId: id,
          type: 'photo',
          path: savedPath,
          caption: 'Label',
          createdAt: now,
        ),
      );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureNoteExists() async {
    if (noteId != null) return;
    saving = true;
    notifyListeners();
    try {
      noteId = DateTime.now().microsecondsSinceEpoch.toString();
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
