String formatNotionDate(DateTime dateTime) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = targetDay.difference(today).inDays;

  final hh = dateTime.hour.toString().padLeft(2, '0');
  final mm = dateTime.minute.toString().padLeft(2, '0');

  if (diff == 0) {
    return '오늘 $hh:$mm';
  }

  if (diff == -1) {
    return '어제 $hh:$mm';
  }

  if (dateTime.year == now.year) {
    return '${dateTime.month}월 ${dateTime.day}일 $hh:$mm';
  }

  return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 $hh:$mm';
}