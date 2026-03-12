import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/features/figures/figures_vm.dart';

class AddToFigureDialog extends StatefulWidget {
  const AddToFigureDialog({
    super.key,
    required this.noteId,
  });

  final int noteId;

  @override
  State<AddToFigureDialog> createState() => _AddToFigureDialogState();
}

class _AddToFigureDialogState extends State<AddToFigureDialog> {
  int? selectedFigureId;
  final TextEditingController panelCtrl = TextEditingController();

  @override
  void dispose() {
    panelCtrl.dispose();
    super.dispose();
  }

  Future<void> _fillSuggestedPanelLabel(int figureId) async {
    final db = context.read<AppDatabase>();
    final suggested = await db.getNextPanelLabel(figureId);

    if (!mounted) return;

    setState(() {
      panelCtrl.text = suggested;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiguresVm>();

    return AlertDialog(
      title: const Text('Figure에 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vm.figures.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '등록된 Figure가 없습니다.\n먼저 Figure를 생성해 주세요.',
                ),
              ),
            DropdownButtonFormField<int>(
              value: selectedFigureId,
              decoration: const InputDecoration(
                labelText: 'Figure',
              ),
              hint: const Text('Figure 선택'),
              items: vm.figures
                  .map(
                    (f) => DropdownMenuItem<int>(
                      value: f.id,
                      child: Text(
                        f.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: vm.figures.isEmpty
                  ? null
                  : (v) async {
                      if (v == null) return;

                      setState(() {
                        selectedFigureId = v;
                      });

                      await _fillSuggestedPanelLabel(v);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: panelCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Panel label',
                hintText: 'A',
              ),
              enabled: vm.figures.isNotEmpty,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: vm.figures.isEmpty
              ? null
              : () async {
                  final figureId = selectedFigureId;
                  final label = panelCtrl.text.trim().toUpperCase();

                  if (figureId == null || label.isEmpty) return;

                  final db = context.read<AppDatabase>();

                  await db.insertFigurePanel(
                    figureId: figureId,
                    panelLabel: label,
                    sourceNoteId: widget.noteId,
                  );

                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
          child: const Text('추가'),
        ),
      ],
    );
  }
}