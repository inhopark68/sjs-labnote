import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../features/scan/scan_result.dart';
import 'ocr_label_parser.dart';

class ImageScanService {
  final OcrLabelParser _parser = OcrLabelParser();

  Future<ScanFromImageResult> scanImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    final barcodeScanner = BarcodeScanner();
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    List<ScanCodeItem> codes = const [];
    String text = '';

    try {
      try {
        final barcodes = await barcodeScanner.processImage(inputImage);
        codes = barcodes
            .map(
              (b) => ScanCodeItem(
                rawValue: b.rawValue,
                displayValue: b.displayValue,
                format: b.format.name,
              ),
            )
            .toList(growable: false);
      } catch (e, st) {
        debugPrint('barcode scan failed: $e');
        debugPrint('$st');
      }

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        text = recognizedText.text;
      } catch (e, st) {
        debugPrint('text scan failed: $e');
        debugPrint('$st');
      }

      final parsedInfo = _parser.parse(text);

      return ScanFromImageResult(
        codes: codes,
        text: text,
        parsed: ParsedScanFields(
          lotNumber: parsedInfo.lotNumber,
          catalogNumber: parsedInfo.catalogNumber,
          company: parsedInfo.company,
          companyCandidates: parsedInfo.companyCandidates,
        ),
      );
    } finally {
      await barcodeScanner.close();
      await textRecognizer.close();
    }
  }
}