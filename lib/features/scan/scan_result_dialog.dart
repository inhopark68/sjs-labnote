import 'package:flutter/material.dart';

import 'scan_result.dart';

class ScanResultDialog extends StatelessWidget {
  final ScanFromImageResult result;

  const ScanResultDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이미지 분석 결과'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'QR / Barcode',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (result.codes.isEmpty)
                const Text('검출된 QR/바코드가 없습니다.')
              else
                ...result.codes.map(
                  (c) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(c.displayValue ?? c.rawValue ?? '(값 없음)'),
                      subtitle: Text(
                        'format: ${c.format}\nraw: ${c.rawValue ?? ''}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'OCR Text',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SelectableText(
                result.text.trim().isEmpty ? '인식된 텍스트가 없습니다.' : result.text,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}