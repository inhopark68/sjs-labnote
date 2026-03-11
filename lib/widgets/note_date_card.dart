import 'package:flutter/material.dart';

class NoteDateCard extends StatelessWidget {
  final DateTime? noteDate;
  final VoidCallback onPickDate;
  final VoidCallback? onClearDate;

  const NoteDateCard({
    super.key,
    required this.noteDate,
    required this.onPickDate,
    this.onClearDate,
  });

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');

    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd $hh:$min:$ss';
  }

  String _formatDateTime(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');

    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final ss = date.second.toString().padLeft(2, '0');

    return '$yyyy-$mm-$dd $hh:$min:$ss';
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDate = noteDate != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.event,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '노트 날짜',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasDate ? _formatDate(noteDate!) : '설정되지 않음',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPickDate,
              child: Text(hasDate ? '변경' : '선택'),
            ),
            if (hasDate && onClearDate != null)
              TextButton(
                onPressed: onClearDate,
                child: const Text('제거'),
              ),
          ],
        ),
      ),
    );
  }
}