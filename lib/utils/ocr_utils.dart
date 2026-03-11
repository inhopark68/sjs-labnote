import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String> extractTextWithMlKit(String imagePath) async {
  final inputImage = InputImage.fromFilePath(imagePath);
  final recognizer = TextRecognizer(
    script: TextRecognitionScript.korean,
  );

  try {
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
      .replaceAll('\u00A0', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}