import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'text_recognizer_service.dart';

class _PlatformTextRecognizerService implements TextRecognizerService {
  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<String?> recognizeFromFilePath(String filePath) async {
    if (_isWindows) return null; // ✅ Windows는 OCR 안 함

    // ✅ Android/iOS에서만 OCR
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(filePath);
      final res = await recognizer.processImage(input);
      return res.text;
    } finally {
      await recognizer.close();
    }
  }

  @override
  Future<String> writeTempImageBytes({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    final dir = await getTemporaryDirectory();

    final safeBase = p
        .basename(suggestedName)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();

    final ext = p.extension(safeBase);
    final baseNoExt = ext.isEmpty
        ? safeBase
        : p.basenameWithoutExtension(safeBase);

    final finalName =
        'ocr_${DateTime.now().microsecondsSinceEpoch}_$baseNoExt${ext.isEmpty ? '.jpg' : ext}';

    final file = File(p.join(dir.path, finalName));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

TextRecognizerService createService() => _PlatformTextRecognizerService();
