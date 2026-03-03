import 'dart:io';
import 'package:flutter/material.dart';

class ThumbImage extends StatelessWidget {
  final String pathOrUrl;
  const ThumbImage({super.key, required this.pathOrUrl});

  @override
  Widget build(BuildContext context) {
    final s = pathOrUrl;

    if (_looksLikeUrl(s)) {
      return Image.network(
        s,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    return Image.file(
      File(s),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  bool _looksLikeUrl(String s) =>
      s.startsWith('http://') ||
      s.startsWith('https://') ||
      s.startsWith('blob:');
}
