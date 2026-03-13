import 'package:flutter/material.dart';

import 'package:labnote/data/database/app_database.dart';

class NoteReagentsSection extends StatelessWidget {
  final List<DbNoteReagent> reagents;
  final bool noteIsDeleted;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDelete;

  const NoteReagentsSection({
    super.key,
    required this.reagents,
    required this.noteIsDeleted,
    required this.onAdd,
    required this.onDelete,
  });

  String _subtitleParts({
    String? company,
    String? cat,
    String? lot,
    String? memo,
  }) {
    final parts = <String>[];

    if (company != null && company.trim().isNotEmpty) {
      parts.add(company.trim());
    }
    if (cat != null && cat.trim().isNotEmpty) {
      parts.add('Cat: ${cat.trim()}');
    }
    if (lot != null && lot.trim().isNotEmpty) {
      parts.add('Lot: ${lot.trim()}');
    }
    if (memo != null && memo.trim().isNotEmpty) {
      parts.add(memo.trim());
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '시약 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('추가'),
              ),
            ],
          ),
        ),
        if (reagents.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('등록된 시약이 없습니다.'),
          )
        else
          ...reagents.map(
            (r) => Card(
              child: ListTile(
                dense: true,
                title: Text(r.name),
                subtitle: Text(
                  _subtitleParts(
                    company: r.company,
                    cat: r.catalogNumber,
                    lot: r.lotNumber,
                    memo: r.memo,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: noteIsDeleted ? null : () => onDelete(r.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}