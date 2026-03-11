import 'package:flutter/material.dart';

import 'package:labnote/features/scan/scan_result.dart';

enum ScanDialogAction {
  insertNote,
  addReagent,
}

class ScanDialogResult {
  final ScanDialogAction action;
  final String combinedText;

  const ScanDialogResult({
    required this.action,
    required this.combinedText,
  });
}

class ScanResultDialog extends StatefulWidget {
  final ScanFromImageResult result;

  const ScanResultDialog({
    super.key,
    required this.result,
  });

  @override
  State<ScanResultDialog> createState() => _ScanResultDialogState();
}

class _ScanResultDialogState extends State<ScanResultDialog> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: _buildInitialText(widget.result),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  String _buildInitialText(ScanFromImageResult result) {
    final lines = <String>[];
    final parsed = result.parsed;

    final company = (parsed.company ?? '').trim();
    final catalogNumber = (parsed.catalogNumber ?? '').trim();
    final lotNumber = (parsed.lotNumber ?? '').trim();
    final rawText = result.text.trim();

    if (company.isNotEmpty) {
      lines.add('회사: $company');
    }
    if (catalogNumber.isNotEmpty) {
      lines.add('카탈로그 번호: $catalogNumber');
    }
    if (lotNumber.isNotEmpty) {
      lines.add('Lot 번호: $lotNumber');
    }

    final codeValues = result.codes
        .map((e) => (e.displayValue ?? e.rawValue ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (codeValues.isNotEmpty) {
      if (lines.isNotEmpty) lines.add('');
      lines.add('[코드]');
      lines.addAll(codeValues);
    }

    if (rawText.isNotEmpty) {
      if (lines.isNotEmpty) lines.add('');
      lines.add('[원본 텍스트]');
      lines.add(rawText);
    }

    return lines.join('\n').trim();
  }

  void _submit(ScanDialogAction action) {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용이 비어 있습니다.')),
      );
      return;
    }

    Navigator.of(context).pop(
      ScanDialogResult(
        action: action,
        combinedText: text,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.result.parsed;
    final hasParsedInfo =
        (parsed.company?.trim().isNotEmpty ?? false) ||
        (parsed.catalogNumber?.trim().isNotEmpty ?? false) ||
        (parsed.lotNumber?.trim().isNotEmpty ?? false);

    return AlertDialog(
      title: const Text('스캔 결과'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasParsedInfo) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '추출 정보',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('회사', parsed.company ?? ''),
                _buildInfoRow('카탈로그', parsed.catalogNumber ?? ''),
                _buildInfoRow('Lot', parsed.lotNumber ?? ''),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _textCtrl,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: '저장할 내용',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => _submit(ScanDialogAction.addReagent),
          child: const Text('시약 추가'),
        ),
        FilledButton(
          onPressed: () => _submit(ScanDialogAction.insertNote),
          child: const Text('노트로 저장'),
        ),
      ],
    );
  }
}