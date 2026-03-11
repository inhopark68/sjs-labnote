import 'package:flutter/material.dart';

class ItemEntryInput {
  final String name;
  final String? catalogNumber;
  final String? lotNumber;
  final String? company;
  final String? memo;

  const ItemEntryInput({
    required this.name,
    this.catalogNumber,
    this.lotNumber,
    this.company,
    this.memo,
  });
}

class _ParsedItem {
  final String? catalog;
  final String? lot;
  final String? company;
  final List<String> nameCandidates;
  final String? memo;

  const _ParsedItem({
    required this.catalog,
    required this.lot,
    required this.company,
    required this.nameCandidates,
    required this.memo,
  });
}

class ItemEntryDialog extends StatefulWidget {
  final String title;
  final bool enableOcr;
  final Future<String?> Function()? onRequestOcrText;

  const ItemEntryDialog({
    super.key,
    required this.title,
    this.enableOcr = false,
    this.onRequestOcrText,
  });

  @override
  State<ItemEntryDialog> createState() => _ItemEntryDialogState();
}

class _ItemEntryDialogState extends State<ItemEntryDialog> {
  final _name = TextEditingController();
  final _catalog = TextEditingController();
  final _lot = TextEditingController();
  final _company = TextEditingController();
  final _memo = TextEditingController();

  bool _ocrRunning = false;

  List<String> _nameCandidates = const [];
  final Set<String> _selectedNames = <String>{};

  @override
  void dispose() {
    _name.dispose();
    _catalog.dispose();
    _lot.dispose();
    _company.dispose();
    _memo.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _submit() {
    if (_nameCandidates.isNotEmpty) {
      final picked = _selectedNames.toList()..sort();
      if (picked.isEmpty) return;

      final first = picked.first;
      if (_name.text.trim().isEmpty) {
        _name.text = first;
      }

      final extra = picked.length > 1 ? picked.skip(1).join('\n') : '';
      if (extra.isNotEmpty && _memo.text.trim().isEmpty) {
        _memo.text = '추가 후보:\n$extra';
      }
    }

    final name = _name.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      ItemEntryInput(
        name: name,
        catalogNumber: _clean(_catalog),
        lotNumber: _clean(_lot),
        company: _clean(_company),
        memo: _clean(_memo),
      ),
    );
  }

  List<String> _lines(String text) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  _ParsedItem _parseItemFromOcr(String raw) {
    final text = raw.replaceAll('\r', '\n');
    final lines = _lines(text);

    String? cat;
    String? lot;
    String? company;
    final nameCandidates = <String>{};
    final memoLines = <String>[];

    String stripPrefix(String line) {
      final idx = line.indexOf(':');
      if (idx >= 0 && idx + 1 < line.length) {
        return line.substring(idx + 1).trim();
      }
      return line.trim();
    }

    bool looksLikeNoise(String s) {
      if (s.length < 2) return true;
      if (RegExp(r'^\d+$').hasMatch(s)) return true;
      return false;
    }

    for (final line in lines) {
      final lower = line.toLowerCase();

      if (RegExp(r'\b10\.\d{4,9}/').hasMatch(line)) {
        memoLines.add(line);
        continue;
      }

      if (lower.startsWith('cat') || lower.startsWith('catalog')) {
        cat ??= stripPrefix(line);
        continue;
      }
      if (lower.startsWith('lot')) {
        lot ??= stripPrefix(line);
        continue;
      }
      if (lower.startsWith('company') ||
          lower.startsWith('vendor') ||
          lower.startsWith('supplier')) {
        company ??= stripPrefix(line);
        continue;
      }

      final cleaned = line.contains(':') ? stripPrefix(line) : line.trim();
      if (!looksLikeNoise(cleaned)) {
        nameCandidates.add(cleaned);
      } else {
        memoLines.add(line);
      }
    }

    final names = nameCandidates.toList();
    if (names.length > 30) {
      names.removeRange(30, names.length);
    }

    return _ParsedItem(
      catalog: cat,
      lot: lot,
      company: company,
      nameCandidates: names,
      memo: memoLines.isEmpty ? null : memoLines.join('\n'),
    );
  }

  Future<void> _runOcrFill() async {
    final fn = widget.onRequestOcrText;
    if (!widget.enableOcr || fn == null) return;

    setState(() => _ocrRunning = true);
    try {
      final raw = await fn();
      if (!mounted || raw == null) return;

      final parsed = _parseItemFromOcr(raw);

      if (_catalog.text.trim().isEmpty &&
          (parsed.catalog ?? '').trim().isNotEmpty) {
        _catalog.text = parsed.catalog!.trim();
      }
      if (_lot.text.trim().isEmpty && (parsed.lot ?? '').trim().isNotEmpty) {
        _lot.text = parsed.lot!.trim();
      }
      if (_company.text.trim().isEmpty &&
          (parsed.company ?? '').trim().isNotEmpty) {
        _company.text = parsed.company!.trim();
      }
      if (_memo.text.trim().isEmpty && (parsed.memo ?? '').trim().isNotEmpty) {
        _memo.text = parsed.memo!.trim();
      }

      final candidates = parsed.nameCandidates;
      if (candidates.isEmpty) {
        if (_memo.text.trim().isEmpty) {
          _memo.text = raw.trim();
        }
        return;
      }

      if (candidates.length == 1) {
        if (_name.text.trim().isEmpty) {
          _name.text = candidates.first;
        }
        setState(() {
          _nameCandidates = const [];
          _selectedNames.clear();
        });
        return;
      }

      setState(() {
        _nameCandidates = candidates;
        _selectedNames
          ..clear()
          ..addAll(candidates);
      });
    } finally {
      if (mounted) {
        setState(() => _ocrRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          if (widget.enableOcr)
            TextButton.icon(
              onPressed: _ocrRunning ? null : _runOcrFill,
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
            if (_nameCandidates.isEmpty) ...[
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: '이름 *'),
                onSubmitted: (_) => _submit(),
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text('OCR로 여러 항목을 찾았습니다.\n추가할 항목을 선택하세요.'),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedNames.addAll(_nameCandidates)),
                    child: const Text('전체 선택'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedNames.clear()),
                    child: const Text('전체 해제'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _nameCandidates.length,
                  itemBuilder: (_, i) {
                    final name = _nameCandidates[i];
                    final checked = _selectedNames.contains(name);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(name),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedNames.add(name);
                          } else {
                            _selectedNames.remove(name);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '대표 이름(선택)',
                  helperText: '선택 목록에서 첫 번째가 자동으로 들어갑니다. 필요하면 수정하세요.',
                ),
              ),
            ],
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: '회사'),
            ),
            TextField(
              controller: _catalog,
              decoration: const InputDecoration(labelText: 'Catalog No.'),
            ),
            TextField(
              controller: _lot,
              decoration: const InputDecoration(labelText: 'Lot No.'),
            ),
            TextField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모'),
              minLines: 1,
              maxLines: 4,
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