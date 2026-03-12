String formatNotionDate(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(date.year, date.month, date.day);
  final diffDays = targetDay.difference(today).inDays;

  String two(int v) => v.toString().padLeft(2, '0');

  String time() {
    return '${two(date.hour)}:${two(date.minute)}';
  }

  String weekday(int w) {
    const map = {
      1: '월요일',
      2: '화요일',
      3: '수요일',
      4: '목요일',
      5: '금요일',
      6: '토요일',
      7: '일요일',
    };
    return map[w]!;
  }

  if (diffDays == 0) return '오늘 ${time()}';
  if (diffDays == -1) return '어제 ${time()}';
  if (diffDays == 1) return '내일 ${time()}';

  if (diffDays.abs() <= 6) {
    return '${weekday(date.weekday)} ${time()}';
  }

  if (date.year == now.year) {
    return '${date.month}월 ${date.day}일 ${time()}';
  }

  return '${date.year}년 ${date.month}월 ${date.day}일 ${time()}';
}