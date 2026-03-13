import 'package:flutter/material.dart';

Widget buildNoteAttachmentPreviewImpl({
  required String filePath,
  required double width,
  required double height,
  required BorderRadius borderRadius,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: borderRadius,
    ),
    child: const Icon(Icons.image_outlined),
  );
}