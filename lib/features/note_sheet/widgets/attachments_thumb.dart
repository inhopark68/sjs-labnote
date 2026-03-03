import 'attachments_thumb_stub.dart'
    if (dart.library.io) 'attachments_thumb_io.dart';

abstract class AttachmentThumb {
  static AttachmentThumb create() => createThumb();
  Widget build({required String path});
}

AttachmentThumb createThumb();