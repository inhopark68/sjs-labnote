import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'attachment_storage.dart';

class AttachmentStorageIo implements AttachmentStorage {
  final String appNameFolder;
  final String attachmentsFolder;
  final String rawFolder;

  const AttachmentStorageIo({
    this.appNameFolder = 'LabNote',
    this.attachmentsFolder = 'attachments',
    this.rawFolder = 'attachments_raw',
  });

  Future<Directory> _rootDir() async {
    final doc = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(doc.path, appNameFolder));
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<Directory> attachmentsDir() async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, attachmentsFolder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> rawAttachmentsDir() async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, rawFolder));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> savePickedFileToAttachments({
    required String noteId,
    required String sourcePath,
    String extension = 'jpg',
  }) async {
    final dir = await attachmentsDir();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final fileName = 'note_${noteId}_$ts.$extension';
    final destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  @override
  Future<String> saveCompressedJpegToAttachments({
    required String noteId,
    required List<int> jpegBytes,
  }) async {
    final dir = await attachmentsDir();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final fileName = 'note_${noteId}_$ts.jpg';
    final destPath = p.join(dir.path, fileName);
    await File(destPath).writeAsBytes(jpegBytes, flush: true);
    return destPath;
  }

  @override
  Future<String> saveRawToRawFolder({
    required String noteId,
    required String sourcePath,
  }) async {
    final dir = await rawAttachmentsDir();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final ext = p.extension(sourcePath).replaceFirst('.', '');
    final fileName = 'raw_note_${noteId}_$ts.${ext.isEmpty ? 'jpg' : ext}';
    final destPath = p.join(dir.path, fileName);
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}

AttachmentStorage createStorage() => const AttachmentStorageIo();
