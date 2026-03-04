import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/pages/note_edit_page.dart'; // ✅ 경로 맞게 수정

class NoteDetailPage extends StatefulWidget {
  final String noteId;

  const NoteDetailPage({super.key, required this.noteId});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Future<Note?> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final db = context.read<AppDatabase>();
    _future = db.getNote(widget.noteId);
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _edit(Note note) async {
    final result = await Navigator.of(context).push<
        (String title, String body, DateTime? noteDate)>(
      MaterialPageRoute(
        builder: (_) => NoteEditPage(
          initialTitle: note.title,
          initialBody: note.body,
          initialNoteDate: note.noteDate,
          titleText: '노트 편집',
        ),
      ),
    );

    if (result == null) return;

    final (title, body, noteDate) = result;
    final db = context.read<AppDatabase>();

    await db.updateNote(id: widget.noteId, title: title, body: body);
    await db.updateNoteDate(widget.noteId, noteDate);

    if (!mounted) return;
    setState(() => _reload());

    // ✅ 홈 목록 갱신 트리거
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDateOnly(Note note) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: note.noteDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final db = context.read<AppDatabase>();
    await db.updateNoteDate(widget.noteId, picked);

    if (!mounted) return;
    setState(() => _reload());
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Note?>(
      future: _future,
      builder: (context, snap) {
        final note = snap.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(note?.title.isNotEmpty == true ? note!.title : '노트'),
            actions: [
              if (note != null)
                IconButton(
                  tooltip: '날짜',
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDateOnly(note),
                ),
              if (note != null)
                IconButton(
                  tooltip: '편집',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _edit(note),
                ),
            ],
          ),
          body: () {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (note == null) {
              return const Center(child: Text('노트를 찾을 수 없습니다.'));
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.noteDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.event, size: 16),
                          const SizedBox(width: 6),
                          Text(_fmtDate(note.noteDate!)),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(note.body),
                    ),
                  ),
                ],
              ),
            );
          }(),
        );
      },
    );
  }
}