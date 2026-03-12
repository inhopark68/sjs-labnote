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
  final panelCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiguresVm>();

    return AlertDialog(
      title: const Text('Figure에 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            value: selectedFigureId,
            hint: const Text('Figure 선택'),
            items: vm.figures
                .map(
                  (f) => DropdownMenuItem(
                    value: f.id,
                    child: Text(f.title),
                  ),
                )
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedFigureId = v;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: panelCtrl,
            decoration: const InputDecoration(
              labelText: 'Panel label',
              hintText: 'A',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () async {
            final figureId = selectedFigureId;
            final label = panelCtrl.text.trim();

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