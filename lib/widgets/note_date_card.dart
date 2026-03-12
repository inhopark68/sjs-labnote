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

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatTime(DateTime date) {
    final hh = _twoDigits(date.hour);
    final mm = _twoDigits(date.minute);
    return '$hh:$mm';
  }

  String _weekdayKorean(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월요일';
      case DateTime.tuesday:
        return '화요일';
      case DateTime.wednesday:
        return '수요일';
      case DateTime.thursday:
        return '목요일';
      case DateTime.friday:
        return '금요일';
      case DateTime.saturday:
        return '토요일';
      case DateTime.sunday:
        return '일요일';
      default:
        return '';
    }
  }

  String _formatNotionStyle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    final diffDays = targetDay.difference(today).inDays;
    final timeText = _formatTime(date);

    if (diffDays == 0) return '오늘 $timeText';
    if (diffDays == -1) return '어제 $timeText';
    if (diffDays == 1) return '내일 $timeText';

    if ((diffDays < 0 && diffDays >= -6) || (diffDays > 0 && diffDays <= 6)) {
      return '${_weekdayKorean(date.weekday)} $timeText';
    }

    if (date.year == now.year) {
      return '${date.month}월 ${date.day}일 $timeText';
    }

    return '${date.year}년 ${date.month}월 ${date.day}일 $timeText';
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
                    hasDate ? _formatNotionStyle(noteDate!) : '설정되지 않음',
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