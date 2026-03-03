import 'dart:html' as html;
import 'package:flutter/material.dart';

import '../../../services/web_idb_attachments.dart';
import 'thumb_image.dart';

class _ThumbImageImpl extends _ThumbImageBase {
  _ThumbImageImpl({required super.pathOrUrl});

  @override
  Widget build(BuildContext context) {
    final s = pathOrUrl;

    if (_looksLikeHttpOrBlobUrl(s)) {
      return Image.network(
        s,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    if (s.startsWith('idb://')) {
      final key = s.substring('idb://'.length);

      return FutureBuilder<({Uint8List bytes, String mime})?>(
        future: WebIdbAttachments.getBytes(key),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final data = snap.data;
          if (data == null) {
            return const Center(child: Icon(Icons.broken_image));
          }

          final blob = html.Blob([data.bytes], data.mime);
          final url = html.Url.createObjectUrlFromBlob(blob);

          // ObjectURL은 필요할 때마다 생성되므로, 여기서는 간단히 표시만 합니다.
          // (많은 이미지에서 메모리 누수 걱정되면 캐시+dispose로 revoke하는 구조로 개선 가능)
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Center(child: Icon(Icons.broken_image)),
          );
        },
      );
    }

    // 웹에서 “파일 경로처럼 보이는 문자열”은 접근 불가 → 아이콘
    return const Center(child: Icon(Icons.insert_drive_file));
  }

  bool _looksLikeHttpOrBlobUrl(String s) =>
      s.startsWith('http://') ||
      s.startsWith('https://') ||
      s.startsWith('blob:');
}

extension on ThumbImage {
  Widget build(BuildContext context) =>
      (this as dynamic).build(context) as Widget;
}
