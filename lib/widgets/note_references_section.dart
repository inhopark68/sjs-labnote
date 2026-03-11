import 'package:flutter/material.dart';

import '../data/app_database.dart';

class NoteReferencesSection extends StatelessWidget {
  final List<DbNoteReference> references;
  final bool noteIsDeleted;
  final VoidCallback onAdd;
  final Future<void> Function(String id) onDelete;

  const NoteReferencesSection({
    super.key,
    required this.references,
    required this.noteIsDeleted,
    required this.onAdd,
    required this.onDelete,
  });

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
                  'References (DOI)',
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
        if (references.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('등록된 DOI가 없습니다.'),
          )
        else
          ...references.map(
            (r) => Card(
              child: ListTile(
                dense: true,
                title: Text(r.doi),
                subtitle: Text((r.memo ?? '').trim()),
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