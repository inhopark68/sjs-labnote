import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> extractTextWithMlKit(String imagePath) async {
  final recognizer = TextRecognizer();
  try {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await recognizer.processImage(inputImage);
    return result.text;
  } finally {
    await recognizer.close();
  }
}

String normalizeOcrText(String raw) {
  return raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trim();
}