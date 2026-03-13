import 'package:flutter/material.dart';
import 'reagent_draft.dart';

class ReagentDraftSubmitResult {
  final String name;
  final String? company;
  final String? catalogNumber;
  final String? lotNumber;
  final String? memo;

  const ReagentDraftSubmitResult({
    required this.name,
    this.company,
    this.catalogNumber,
    this.lotNumber,
    this.memo,
  });
}

class AddReagentDraftDialog extends StatefulWidget {
  final ReagentDraft initialDraft;

  const AddReagentDraftDialog({
    super.key,
    required this.initialDraft,
  });

  @override
  State<AddReagentDraftDialog> createState() => _AddReagentDraftDialogState();
}

class _AddReagentDraftDialogState extends State<AddReagentDraftDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _catalogCtrl;
  late final TextEditingController _lotCtrl;
  late final TextEditingController _memoCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDraft;
    _nameCtrl = TextEditingController(text: d.name);
    _companyCtrl = TextEditingController(text: d.company ?? '');
    _catalogCtrl = TextEditingController(text: d.catalogNumber ?? '');
    _lotCtrl = TextEditingController(text: d.lotNumber ?? '');
    _memoCtrl = TextEditingController(text: d.memo ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _catalogCtrl.dispose();
    _lotCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('시약 정보 확인'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '이름'),
              ),
              TextField(
                controller: _companyCtrl,
                decoration: const InputDecoration(labelText: '회사명'),
              ),
              TextField(
                controller: _catalogCtrl,
                decoration: const InputDecoration(labelText: 'Catalog No'),
              ),
              TextField(
                controller: _lotCtrl,
                decoration: const InputDecoration(labelText: 'Lot No'),
              ),
              TextField(
                controller: _memoCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '메모'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(
              context,
              ReagentDraftSubmitResult(
                name: name,
                company: _companyCtrl.text.trim().isEmpty
                    ? null
                    : _companyCtrl.text.trim(),
                catalogNumber: _catalogCtrl.text.trim().isEmpty
                    ? null
                    : _catalogCtrl.text.trim(),
                lotNumber: _lotCtrl.text.trim().isEmpty
                    ? null
                    : _lotCtrl.text.trim(),
                memo: _memoCtrl.text.trim().isEmpty
                    ? null
                    : _memoCtrl.text.trim(),
              ),
            );
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}