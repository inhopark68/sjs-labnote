import 'dart:io';
import 'package:flutter/material.dart';
import 'attachments_thumb.dart';

class _IoThumb implements AttachmentThumb {
  @override
  Widget build({required String path}) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }
}

AttachmentThumb createThumb() => _IoThumb();
