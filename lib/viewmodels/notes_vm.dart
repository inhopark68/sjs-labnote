import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';

class NoteListItem {
  final String id;
  final String title;
<<<<<<< HEAD
  final String bodyPreview;
=======
  final String body;
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  final bool isPinned;
  final DateTime updatedAt;

  NoteListItem({
    required this.id,
    required this.title,
<<<<<<< HEAD
    required this.bodyPreview,
=======
    required this.body,
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
    required this.isPinned,
    required this.updatedAt,
  });

  factory NoteListItem.fromNote(Note n) => NoteListItem(
<<<<<<< HEAD
        id: n.id,
        title: n.title,
        bodyPreview: _preview(n.body),
        isPinned: n.isPinned,
        updatedAt: n.updatedAt,
      );

  static String _preview(String body) {
    final s = body.replaceAll('\n', ' ').trim();
    if (s.length <= 80) return s;
    return '${s.substring(0, 80)}…';
=======
    id: n.id,
    title: n.title,
    body: n.body,
    isPinned: n.isPinned,
    updatedAt: n.updatedAt,
  );

  String get bodyPreview {
    final s = body.replaceAll('\n', ' ').trim();
    return s.length <= 80 ? s : '${s.substring(0, 80)}…';
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  }
}

class NotesVM extends ChangeNotifier {
  final NotesRepository _db;

  NotesVM(this._db) {
<<<<<<< HEAD
    // ✅ 생성자에서 async를 직접 await할 수 없어서 unawaited로 실행
    unawaited(_bootstrap());
=======
    unawaited(refresh());
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _query = '';
  String get query => _query;

  List<NoteListItem> _items = const [];
  List<NoteListItem> get items => _items;

  Timer? _debounce;
<<<<<<< HEAD
  int _refreshToken = 0;

  bool _bootstrapped = false;

  /// ✅ 첫 실행 시 비어있으면 샘플 1개 생성
  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    try {
      await refresh();

      // refresh()가 끝난 뒤에도 비어있으면 샘플 노트 생성
      if (_items.isEmpty) {
        // addNote()는 내부 refresh/로딩을 또 부르므로 여기서는 직접 insert 후 refresh가 더 안전
        await _db.insertNote(title: '첫 노트', body: '여기에 내용을 입력하세요.');
        await refresh(); // ✅ 생성 후 목록 반영
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
      unawaited(refresh());
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

  Future<Note> getNote(String id) async {
    final note = await _db.getNote(id);
    if (note == null) throw StateError('Note not found: $id');
    return note;
  }

  Future<void> addNote({required String title, required String body}) async {
    debugPrint('ADD NOTE: title="${title.trim()}", bodyLen=${body.length}');
    _setLoading(true);
    try {
      await _db.insertNote(title: title, body: body);
      debugPrint('ADD NOTE: insert OK');
      await refresh();
      debugPrint('ADD NOTE: refresh OK, items=${_items.length}');
    } catch (e, st) {
      debugPrint('ADD NOTE FAILED: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
=======

  void setQuery(String v) {
    final next = v.trim();
    if (next == _query) return;

    _query = next;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    _setLoading(true);
    try {
      final notes = await _db.listNotes(query: _query);
      _items = notes.map(NoteListItem.fromNote).toList(growable: false);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addNote({required String title, required String body}) async {
    await _db.insertNote(title: title, body: body);
    await refresh();
  }

>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
  }) async {
<<<<<<< HEAD
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

=======
    await _db.updateNote(id: id, title: title, body: body);
    await refresh();
  }

  Future<void> deleteNoteById(String id) async {
    await _db.deleteNote(id);
    await refresh();
  }

  Future<void> togglePin(String id) async {
    await _db.togglePin(id);
    await refresh();
  }

  Future<int> debugCountAll() async {
    final notes = await _db.listNotes(query: '');
    return notes.length;
  }

>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
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
<<<<<<< HEAD
}
=======
}
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
