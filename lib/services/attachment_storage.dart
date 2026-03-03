import 'attachment_storage_stub.dart'
    if (dart.library.io) 'attachment_storage_io.dart';

abstract class AttachmentStorage {
  Future<String> savePickedFileToAttachments({
    required String noteId,
    required String sourcePath,
    String extension,
  });

  Future<String> saveCompressedJpegToAttachments({
    required String noteId,
    required List<int> jpegBytes,
  });

  Future<String> saveRawToRawFolder({
    required String noteId,
    required String sourcePath,
  });
}

// ✅ 이 함수가 있어야 AppBootstrap에서 createAttachmentStorage()가 동작합니다.
AttachmentStorage createAttachmentStorage() => createStorage();
