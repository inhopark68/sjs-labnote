import 'dart:typed_data';

import 'attachment_storage.dart';
import 'web_idb_attachments.dart'; // ✅ 반드시 필요

class AttachmentStorageWeb implements AttachmentStorage {
  const AttachmentStorageWeb();

  @override
  Future<String> savePickedFileToAttachments({
    required String noteId,
    required String sourcePath,
    String extension = 'jpg',
  }) async {
    // 웹에서는 sourcePath(File path)가 의미 없음
    throw UnsupportedError(
      'Web: savePickedFileToAttachments is not supported. Use saveCompressedJpegToAttachments(bytes).',
    );
  }

  @override
  Future<String> saveCompressedJpegToAttachments({
    required String noteId,
    required List<int> jpegBytes,
  }) async {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final key = 'note_${noteId}_$ts.jpg';
    final bytes = Uint8List.fromList(jpegBytes);

    await WebIdbAttachments.putBytes(
      key: key,
      bytes: bytes,
      mime: 'image/jpeg',
    );

    // ✅ path 대신 “idb://키”를 반환 (새로고침 후에도 유효)
    return 'idb://$key';
  }

  @override
  Future<String> saveRawToRawFolder({
    required String noteId,
    required String sourcePath,
  }) async {
    throw UnsupportedError('Web: saveRawToRawFolder is not supported.');
  }
}

AttachmentStorage createStorage() => const AttachmentStorageWeb();
