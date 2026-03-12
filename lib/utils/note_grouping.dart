import 'package:labnote/models/note_group.dart';
import 'package:labnote/models/note_list_item.dart';

List<NoteGroup> groupNotesByDate(List<NoteListItem> notes) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final Map<String, List<NoteListItem>> groups = {};

  for (final note in notes) {
    final d = note.updatedAt;
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;

    String key;

    if (diff == 0) {
      key = '오늘';
    } else if (diff == -1) {
      key = '어제';
    } else if (diff >= -6 && diff < 0) {
      key = '이번 주';
    } else if (d.year == now.year) {
      key = '${d.month}월';
    } else {
      key = '${d.year}년';
    }

    groups.putIfAbsent(key, () => []).add(note);
  }

  const order = ['오늘', '어제', '이번 주'];

  final result = <NoteGroup>[];

  for (final key in order) {
    final items = groups.remove(key);
    if (items != null && items.isNotEmpty) {
      result.add(NoteGroup(title: key, items: items));
    }
  }

  final restKeys = groups.keys.toList()
    ..sort((a, b) => b.compareTo(a));

  for (final key in restKeys) {
    final items = groups[key]!;
    result.add(NoteGroup(title: key, items: items));
  }

  return result;
}