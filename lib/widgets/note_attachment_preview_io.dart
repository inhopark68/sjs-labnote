import 'dart:io';

import 'package:flutter/material.dart';

Widget buildNoteAttachmentPreviewImpl({
  required String filePath,
  required double width,
  required double height,
  required BorderRadius borderRadius,
}) {
  final file = File(filePath);

  if (!file.existsSync()) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.image_not_supported_outlined),
    );
  }

  return ClipRRect(
    borderRadius: borderRadius,
    child: Image.file(
      file,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: borderRadius,
          ),
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    ),
  );
}