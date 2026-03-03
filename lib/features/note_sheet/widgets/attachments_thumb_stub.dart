import 'package:flutter/material.dart';
import 'attachments_thumb.dart';

class _WebThumb implements AttachmentThumb {
  @override
  Widget build({required String path}) {
    return const Center(child: Icon(Icons.insert_drive_file));
  }
}

AttachmentThumb createThumb() => _WebThumb();
