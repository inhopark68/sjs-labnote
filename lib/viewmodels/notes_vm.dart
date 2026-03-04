import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';

class NoteListItem {
  final String id;
  final String title;
  final String body;
  final bool isPinned;
  final DateTime updatedAt;

  NoteListItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isPinned,
    required this.updatedAt,
  });

  String get bodyPreview {
    final s = body.replaceAll('\n', ' ').trim();
    return s.length <= 80 ? s : '${s.substring(0, 80)}…';
  }

  factory NoteListItem.fromNote(Note n) => NoteListItem(
        id: n.id,
        title: n.title,
        body: n.body,
        isPinned: n.isPinned,
        updatedAt: n.updatedAt,
      );
}

class NotesVM extends ChangeNotifier {
  final NotesRepository _db;

  NotesVM(this._db) {
    _bootstrap();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _query = '';
  String get query => _query;

  List<NoteListItem> _items = const [];
  List<NoteListItem> get items => _items;

  Timer? _debounce;
  int _refreshToken = 0;

  bool _bootstrapped = false;

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      await refresh();

      if (_items.isEmpty) {
        await _db.insertNote(title: '첫 노트', body: '여기에 내용을 입력하세요.');
        await refresh();
      }
    } catch (e, st) {
      debugPrint('BOOTSTRAP FAILED: $e');
      debugPrint('$st');
    }
  }

  void setQuery(String v) {
    final next = v.trim();
    if (next == _query) return;

    _query = next;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });
  }

  Future<void> refresh() async {
    final token = ++_refreshToken;

    _setLoading(true);
    try {
      final notes = await _db.listNotes(query: _query);
      if (token != _refreshToken) return;

      _items = notes.map(NoteListItem.fromNote).toList(growable: false);
      notifyListeners();
    } catch (e, st) {
      debugPrint('REFRESH FAILED: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      if (token == _refreshToken) _setLoading(false);
    }
  }

  Future<void> addNote({required String title, required String body}) async {
    _setLoading(true);
    try {
      await _db.insertNote(title: title, body: body);
      await refresh();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
  }) async {
    _setLoading(true);
    try {
      await _db.updateNote(id: id, title: title, body: body);
      await refresh();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteNoteById(String id) async {
    _setLoading(true);
    try {
      await _db.deleteNote(id);
      await refresh();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> togglePin(String id) async {
    _setLoading(true);
    try {
      await _db.togglePin(id);
      await refresh();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    if (_isLoading == v) return;
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}