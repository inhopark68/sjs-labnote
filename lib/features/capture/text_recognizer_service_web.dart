import 'dart:typed_data';

import 'text_recognizer_service.dart';

class _WebTextRecognizerService implements TextRecognizerService {
  @override
  Future<String?> recognizeFromFilePath(String filePath) async => null;

  @override
  Future<String> writeTempImageBytes({
    required Uint8List bytes,
    required String suggestedName,
  }) async {
    throw UnsupportedError('Web does not support temp file writing.');
  }
}

TextRecognizerService createService() => _WebTextRecognizerService();
