import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../features/scan/scan_result.dart';

class ImageScanService {
  Future<ScanFromImageResult> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    final barcodeScanner = BarcodeScanner();
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final codes = barcodes
          .map(
            (b) => ScanCodeItem(
              rawValue: b.rawValue,
              displayValue: b.displayValue,
              format: b.format.name,
            ),
          )
          .toList(growable: false);

      return ScanFromImageResult(
        codes: codes,
        text: recognizedText.text,
      );
    } finally {
      await barcodeScanner.close();
      await textRecognizer.close();
    }
  }
}