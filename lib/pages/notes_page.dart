import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart';
import '../note_detail_page.dart';
import '../../widgets/notes_list_view.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  AppDatabase get _db => context.read<AppDatabase>();

  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
    });

    final notes = await _db.listNotes(
      query: _searchCtrl.text,
    );

    if (!mounted) return;

    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _createNote() async {
    final id = await _db.insertNote(
      title: '',
      body: '',
    );

    if (!mounted) return;

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(noteId: id),
      ),
    );

    if (changed == true) {
      _loadNotes();
    }
  }

  Future<void> _openNote(Note note) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailPage(noteId: note.id),
      ),
    );

    if (changed == true) {
      _loadNotes();
    }
  }

  Future<void> _togglePin(Note note) async {
    try {
      await _db.togglePin(note.id);
      await _loadNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('고정 상태 변경 실패: $e')),
      );
    }
  }

  Future<void> _moveToTrash(Note note) async {
    try {
      await _db.deleteNote(note.id);
      await _loadNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('휴지통 이동 실패: $e')),
      );
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: '검색',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchCtrl.clear();
            _loadNotes();
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) => _loadNotes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연구 노트'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildSearchField(),
            ),
            Expanded(
              child: NotesListView(
                notes: _notes,
                loading: _loading,
                onRefresh: _loadNotes,
                onTapNote: _openNote,
                onTogglePin: _togglePin,
                onMoveToTrash: _moveToTrash,
              ),
            ),
          ],
        ),
      ),
    );
  }
}