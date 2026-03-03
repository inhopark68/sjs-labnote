import 'dart:typed_data';

import 'text_recognizer_service_stub.dart'
    if (dart.library.io) 'text_recognizer_service_io.dart'
    if (dart.library.html) 'text_recognizer_service_web.dart';

abstract class TextRecognizerService {
  /// 지원 안 하면 null 반환하도록(Windows/웹에서 편하게 처리)
  Future<String?> recognizeFromFilePath(String filePath);

  /// bytes 임시파일 저장(Windows에서도 촬영/저장 흐름에 쓰일 수 있어서 유지)
  Future<String> writeTempImageBytes({
    required Uint8List bytes,
    required String suggestedName,
  });
}

TextRecognizerService createTextRecognizerService() => createService();
