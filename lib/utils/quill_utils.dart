import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

String quillDocumentToStoredJson(quill.Document document) {
  try {
    final deltaJson = document.toDelta().toJson();
    return jsonEncode(deltaJson);
  } catch (_) {
    return jsonEncode([
      {'insert': '\n'}
    ]);
  }
}

quill.Document quillDocumentFromStoredText(String? stored) {
  final raw = (stored ?? '').trim();

  if (raw.isEmpty) {
    return quill.Document();
  }

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return quill.Document.fromJson(decoded);
      }
    } catch (_) {}
  }

  return quill.Document()..insert(0, raw);
}

String quillStoredTextToPlain(String? stored) {
  final raw = (stored ?? '').trim();

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