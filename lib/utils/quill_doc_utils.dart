import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

Set<String> extractImagePathsFromDoc(quill.QuillController controller) {
  final paths = <String>{};

  for (final op in controller.document.toDelta().toList()) {
    final data = op.data;
    if (data is Map && data['image'] is String) {
      paths.add(data['image'] as String);
    }
  }

  return paths;
}

String encodeDoc(quill.QuillController controller) {
  final json = controller.document.toDelta().toJson();
  return jsonEncode(json);
}

String quillStoredTextToPlain(String? encodedOrText) {
  final raw = (encodedOrText ?? '').trim();
  if (raw.isEmpty) return '';

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        return doc.toPlainText().replaceAll('\n', ' ').trim();
      }
    } catch (_) {}
  }

  return raw.replaceAll('\n', ' ').trim();
}

void decodeDocOrPlainText(
  quill.QuillController controller,
  String? encodedOrText,
) {
  final raw = (encodedOrText ?? '').trim();

  if (raw.isEmpty) {
    controller.document = quill.Document()..insert(0, '');
    controller.updateSelection(
      const TextSelection.collapsed(offset: 0),
      quill.ChangeSource.local,
    );
    return;
  }

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        controller.document = doc;
        controller.updateSelection(
          const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.local,
        );
        return;
      }
    } catch (_) {}
  }

  controller.document = quill.Document()..insert(0, raw);
  controller.updateSelection(
    const TextSelection.collapsed(offset: 0),
    quill.ChangeSource.local,
  );
}