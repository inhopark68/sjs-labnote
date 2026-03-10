import 'package:flutter/material.dart';

import 'scan_result.dart';

class ScanResultDialog extends StatelessWidget {
  final ScanFromImageResult result;

  const ScanResultDialog({
    super.key,
    required this.result,
  });

  String _buildCombinedText() {
    final lines = <String>[];

    if (result.parsed.hasAny) {
      lines.add('[Parsed]');
      if ((result.parsed.company?.isNotEmpty ?? false)) {
        lines.add('Company: ${result.parsed.company}');
      }
      if ((result.parsed.catalogNumber?.isNotEmpty ?? false)) {
        lines.add('Catalog: ${result.parsed.catalogNumber}');
      }
      if ((result.parsed.lotNumber?.isNotEmpty ?? false)) {
        lines.add('Lot: ${result.parsed.lotNumber}');
      }
      if (result.parsed.companyCandidates.length > 1) {
        lines.add('Company Candidates: ${result.parsed.companyCandidates.join(', ')}');
      }
      lines.add('');
    }

    if (result.codes.isNotEmpty) {
      lines.add('[Codes]');
      for (final code in result.codes) {
        final value = (code.rawValue ?? code.displayValue ?? '').trim();
        lines.add('${code.format}: $value');
      }
      lines.add('');
    }

    if (result.text.trim().isNotEmpty) {
      lines.add('[OCR]');
      lines.add(result.text.trim());
    }

    return lines.join('\n').trim();
  }

  @override
  Widget build(BuildContext context) {
    final combinedText = _buildCombinedText();

    return AlertDialog(
      title: const Text('이미지 분석 결과'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.parsed.hasAny) ...[
                const Text(
                  '추출된 필드',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        title: const Text('Company'),
                        subtitle: Text(result.parsed.company ?? '(없음)'),
                      ),
                      ListTile(
                        dense: true,
                        title: const Text('Catalog Number'),
                        subtitle: Text(result.parsed.catalogNumber ?? '(없음)'),
                      ),
                      ListTile(
                        dense: true,
                        title: const Text('Lot Number'),
                        subtitle: Text(result.parsed.lotNumber ?? '(없음)'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        (c.displayValue?.trim().isNotEmpty ?? false)
                            ? c.displayValue!
                            : (c.rawValue ?? '(값 없음)'),
                      ),
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
                result.text.trim().isEmpty
                    ? '인식된 텍스트가 없습니다.'
                    : result.text,
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
        TextButton(
          onPressed: combinedText.isEmpty
              ? null
              : () => Navigator.pop(context, combinedText),
          child: const Text('노트에 넣기'),
        ),
      ],
    );
  }
}