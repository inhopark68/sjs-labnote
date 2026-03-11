import 'package:flutter/material.dart';

class DoiEntryInput {
  final String doi;
  final String? memo;

  const DoiEntryInput({
    required this.doi,
    this.memo,
  });
}

class DoiEntryDialog extends StatefulWidget {
  final bool enableOcr;
  final Future<String?> Function()? onRequestOcrText;

  const DoiEntryDialog({
    super.key,
    this.enableOcr = false,
    this.onRequestOcrText,
  });

  @override
  State<DoiEntryDialog> createState() => _DoiEntryDialogState();
}

class _DoiEntryDialogState extends State<DoiEntryDialog> {
  final _doiCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool _ocrRunning = false;

  List<String> _candidates = const [];
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _doiCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _extractDoisFromText(String text) {
    final re = RegExp(
      r'\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b',
      caseSensitive: false,
    );

    final found = <String>{};
    for (final m in re.allMatches(text)) {
      final doi = m.group(0)?.trim();
      if (doi != null && doi.isNotEmpty) {
        found.add(doi);
      }
    }

    final list = found.toList()..sort();
    return list;
  }

  Future<void> _runOcrAndExtract() async {
    final fn = widget.onRequestOcrText;
    if (!widget.enableOcr || fn == null) return;

    setState(() => _ocrRunning = true);
    try {
      final raw = await fn();
      if (!mounted || raw == null) return;

      final dois = _extractDoisFromText(raw);
      if (dois.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR 결과에서 DOI(10.xxxx/xxxx)를 찾지 못했습니다.'),
          ),
        );
        return;
      }

      if (dois.length == 1) {
        _doiCtrl.text = dois.first;
        setState(() {
          _candidates = const [];
          _selected.clear();
        });
        return;
      }

      setState(() {
        _candidates = dois;
        _selected
          ..clear()
          ..addAll(dois);
      });
    } finally {
      if (mounted) {
        setState(() => _ocrRunning = false);
      }
    }
  }

  void _submit() {
    final memo = _clean(_memoCtrl);

    if (_candidates.isNotEmpty) {
      final picked = _selected.toList()..sort();
      if (picked.isEmpty) return;

      Navigator.pop(
        context,
        picked
            .map((d) => DoiEntryInput(doi: d, memo: memo))
            .toList(growable: false),
      );
      return;
    }

    final doi = _doiCtrl.text.trim();
    if (doi.isEmpty) return;

    Navigator.pop(context, DoiEntryInput(doi: doi, memo: memo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('DOI 추가')),
          if (widget.enableOcr)
            TextButton.icon(
              onPressed: _ocrRunning ? null : _runOcrAndExtract,
              icon: _ocrRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined, size: 18),
              label: Text(_ocrRunning ? 'OCR중…' : 'OCR'),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_candidates.isEmpty) ...[
              TextField(
                controller: _doiCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'DOI * (예: 10.xxxx/xxxx)',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text('OCR로 여러 DOI를 찾았습니다.\n추가할 DOI를 선택하세요.'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.addAll(_candidates)),
                    child: const Text('전체 선택'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('전체 해제'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _candidates.length,
                  itemBuilder: (_, i) {
                    final doi = _candidates[i];
                    final checked = _selected.contains(doi);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(doi),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(doi);
                          } else {
                            _selected.remove(doi);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모(선택)'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('추가'),
        ),
      ],
    );
  }
}