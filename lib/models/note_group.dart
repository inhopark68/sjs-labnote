import 'package:labnote/models/note_list_item.dart';

class NoteGroup {
  final String title;
  final List<NoteListItem> items;

  const NoteGroup({
    required this.title,
    required this.items,
  });
}