import 'package:flutter/material.dart';

import 'package:labnote/data/database/app_database.dart';
import '../utils/quill_doc_utils.dart';

class NotesListView extends StatelessWidget {
  final List<Note> notes;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(Note note) onTapNote;
  final void Function(Note note) onTogglePin;
  final void Function(Note note) onMoveToTrash;

  const NotesListView({
    super.key,
    required this.notes,
    required this.loading,
    required this.onRefresh,
    required this.onTapNote,
    required this.onTogglePin,
    required this.onMoveToTrash,
  });

  String _titleOf(Note note) {
    final t = quillStoredTextToPlain(note.title);
    return t.isEmpty ? '(제목 없음)' : t;
  }

  String _previewOf(Note note) {
    final body = quillStoredTextToPlain(note.body);
    if (body.isEmpty) return '내용 없음';
    if (body.length <= 120) return body;
    return '${body.substring(0, 120)}...';
  }

  String _dateText(Note note) {
    final dt = note.updatedAt;
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  String _noteDateText(Note note) {
    final dt = note.noteDate;
    if (dt == null) return '날짜 없음';

    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Widget _buildNoteTile(BuildContext context, Note note) {
    final title = _titleOf(note);
    final preview = _previewOf(note);
    final dateText = _dateText(note);

    return Card(
      color: note.isPinned
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Row(
          children: [
            if (note.isPinned) ...[
              Icon(
                Icons.push_pin,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '실험일: ${_noteDateText(note)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                dateText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        onTap: () => onTapNote(note),

        // 오른쪽 trailing에 pin 토글 버튼을 항상 노출
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: note.isPinned ? '고정 해제' : '상단 고정',
              icon: Icon(
                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.isPinned
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => onTogglePin(note),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'trash':
                    onMoveToTrash(note);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'trash',
                  child: Text('휴지통으로 이동'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notes.isEmpty) {
      return const Center(
        child: Text('표시할 노트가 없습니다.'),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteTile(context, note);
        },
      ),
    );
  }
}