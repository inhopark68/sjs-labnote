import 'package:flutter/widgets.dart';

import 'note_attachment_preview_stub.dart'
    if (dart.library.io) 'note_attachment_preview_io.dart'
    if (dart.library.html) 'note_attachment_preview_web.dart';

Widget buildNoteAttachmentPreview({
  required String filePath,
  required double width,
  required double height,
  required BorderRadius borderRadius,
}) {
  return buildNoteAttachmentPreviewImpl(
    filePath: filePath,
    width: width,
    height: height,
    borderRadius: borderRadius,
  );
}