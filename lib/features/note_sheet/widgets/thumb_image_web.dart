import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../services/web_idb_attachments.dart';

class ThumbImage extends StatefulWidget {
  final String pathOrUrl;
  const ThumbImage({super.key, required this.pathOrUrl});

  @override
  State<ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<ThumbImage> {
  String? _objectUrl;
  String? _objectUrlKey;

  @override
  void dispose() {
    _revokeUrl();
    super.dispose();
  }

  void _revokeUrl() {
    final url = _objectUrl;
    if (url != null) html.Url.revokeObjectUrl(url);
    _objectUrl = null;
    _objectUrlKey = null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.pathOrUrl;

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

          if (_objectUrl != null && _objectUrlKey == key) {
            return Image.network(_objectUrl!, fit: BoxFit.cover);
          }

          _revokeUrl();
          final blob = html.Blob([data.bytes], data.mime);
          final url = html.Url.createObjectUrlFromBlob(blob);
          _objectUrl = url;
          _objectUrlKey = key;

          return Image.network(url, fit: BoxFit.cover);
        },
      );
    }

    return const Center(child: Icon(Icons.insert_drive_file));
  }

  bool _looksLikeHttpOrBlobUrl(String s) =>
      s.startsWith('http://') ||
      s.startsWith('https://') ||
      s.startsWith('blob:');
}
