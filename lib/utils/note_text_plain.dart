import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;

String noteStoredTextToPlain(String? encodedOrText) {
  final raw = (encodedOrText ?? '').trim();
  if (raw.isEmpty) return '';

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        return doc.toPlainText().replaceAll('\n', ' ').trim();
      }
    } catch (_) {
      // Quill JSON 파싱 실패 시 일반 문자열로 처리
    }
  }

  return raw.replaceAll('\n', ' ').trim();
}