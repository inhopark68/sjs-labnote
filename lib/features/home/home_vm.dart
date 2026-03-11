import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/models/note_list_item.dart';
import 'package:labnote/services/backup_service.dart';
import 'package:labnote/utils/note_text_plain.dart';

class HomeVm extends ChangeNotifier {
  final AppDatabase _data;

  HomeVm(this._data);

  bool searchVisible = false;
  String query = '';

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;

  final List<NoteListItem> items = [];

  static const int _pageSize = 20;

  Timer? _searchDebounce;

  /// refresh 중복 실행 / 오래된 결과 반영 방지
  int _requestToken = 0;

  /// cursor 기반 다음 페이지 기준값
  _NoteCursor? _nextCursor;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> init() async {
    final all = await _data.debugCountAllRows();
    if (all == 0) {
      await _data.insertNote(title: '첫 노트', body: 'DB 연결 테스트');
    }
    await refresh();
  }

  Future<int> insertEmptyAndReturnId() async {
    final id = await _data.insertNote(title: '', body: '');
    await refresh();
    return id;
  }

  void toggleSearch() {
    searchVisible = !searchVisible;

    if (!searchVisible && query.isNotEmpty) {
      query = '';
      _searchDebounce?.cancel();
      unawaited(refresh());
    }

    notifyListeners();
  }

  void setQuery(String v) {
    if (query == v) return;

    query = v;
    notifyListeners();

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    final currentToken = ++_requestToken;

    loading = true;
    loadingMore = false;
    hasMore = true;
    _nextCursor = null;
    notifyListeners();

    try {
      final fetched = await _fetchFirstPage();

      if (currentToken != _requestToken) return;

      final pageItems = fetched
          .take(_pageSize)
          .map(_toListItem)
          .toList(growable: false);

      items
        ..clear()
        ..addAll(pageItems);

      hasMore = fetched.length > _pageSize;
      _nextCursor = items.isNotEmpty ? _cursorFromItem(items.last) : null;
    } finally {
      if (currentToken == _requestToken) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;
    if (_nextCursor == null && items.isNotEmpty) return;

    final currentToken = _requestToken;

    loadingMore = true;
    notifyListeners();

    try {
      final cursor = _nextCursor;
      if (cursor == null) {
        hasMore = false;
        return;
      }

      final fetched = await _fetchNextPage(cursor);

      if (currentToken != _requestToken) return;

      final moreItems = fetched
          .take(_pageSize)
          .map(_toListItem)
          .toList(growable: false);

      final existingIds = items.map((e) => e.id).toSet();
      final deduped = moreItems
          .where((e) => !existingIds.contains(e.id))
          .toList(growable: false);

      items.addAll(deduped);

      hasMore = fetched.length > _pageSize;
      _nextCursor = items.isNotEmpty ? _cursorFromItem(items.last) : null;
    } finally {
      if (currentToken == _requestToken) {
        loadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteNoteOptimistic(int noteId) async {
    final index = items.indexWhere((e) => e.id == noteId);
    if (index < 0) {
      await _data.deleteNote(noteId);
      await refresh();
      return;
    }

    final removed = items.removeAt(index);
    notifyListeners();

    try {
      await _data.deleteNote(noteId);

      if (items.length < _pageSize && hasMore) {
        final cursor = _nextCursor;
        if (cursor != null) {
          final fetched = await _fetchNextPage(cursor);

          final moreItems = fetched
              .take(_pageSize)
              .map(_toListItem)
              .toList(growable: false);

          final existingIds = items.map((e) => e.id).toSet();
          items.addAll(
            moreItems.where((e) => !existingIds.contains(e.id)),
          );

          hasMore = fetched.length > _pageSize;
          _nextCursor = items.isNotEmpty ? _cursorFromItem(items.last) : null;
        }
      }
    } catch (e) {
      items.insert(index, removed);
      _sortItemsInMemory();
      notifyListeners();
      rethrow;
    }

    _sortItemsInMemory();
    notifyListeners();
  }

  Future<void> restoreDeletedNote(int noteId) async {
    await _data.restoreNote(noteId);
    await refresh();
  }

  Future<void> togglePin(int noteId) async {
    final index = items.indexWhere((e) => e.id == noteId);

    if (index < 0) {
      await _data.togglePin(noteId);
      await refresh();
      return;
    }

    final oldItem = items[index];
    final optimistic = oldItem.copyWith(
      isPinned: !oldItem.isPinned,
      updatedAt: DateTime.now(),
    );

    items[index] = optimistic;
    _sortItemsInMemory();
    notifyListeners();

    try {
      await _data.togglePin(noteId);
    } catch (e) {
      final rollbackIndex = items.indexWhere((e) => e.id == noteId);
      if (rollbackIndex >= 0) {
        items[rollbackIndex] = oldItem;
      } else {
        items.add(oldItem);
      }
      _sortItemsInMemory();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<NoteListRow>> _fetchFirstPage() {
    return _data.listNoteRowsFirstPage(
      query: query.trim(),
      limit: _pageSize + 1,
    );
  }

  Future<List<NoteListRow>> _fetchNextPage(_NoteCursor cursor) {
    return _data.listNoteRowsAfterCursor(
      query: query.trim(),
      limit: _pageSize + 1,
      lastUpdatedAt: cursor.updatedAt,
      lastId: cursor.id,
      lastIsPinned: cursor.isPinned,
    );
  }

  _NoteCursor _cursorFromItem(NoteListItem item) {
    return _NoteCursor(
      id: item.id,
      updatedAt: item.updatedAt,
      isPinned: item.isPinned,
    );
  }

  void _sortItemsInMemory() {
    items.sort((a, b) {
      final pinCompare =
          (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
      if (pinCompare != 0) return pinCompare;

      final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCompare != 0) return updatedCompare;

      return b.id.compareTo(a.id);
    });
  }

  NoteListItem _toListItem(NoteListRow n) {
    final project = n.project?.trim();

    return NoteListItem(
      id: n.id,
      title: noteStoredTextToPlain(n.title),
      bodyPreview: noteStoredTextToPlain(n.preview),
      createdAt: n.createdAt,
      updatedAt: n.updatedAt,
      isPinned: n.isPinned,
      isLocked: n.isLocked,
      attachmentCount: 0,
      reagentCount: 0,
      cellCount: 0,
      equipmentCount: 0,
      hasExpiredReagent: false,
      hasExpiringSoon: false,
      tagNames: [
        if (project != null && project.isNotEmpty) project,
      ],
    );
  }

  Future<void> exportBackupPlain(BuildContext context) async {
    final svc = context.read<BackupService>();
    await svc.exportBackup(password: null);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 내보내기 완료')),
    );
  }

  Future<void> importBackupWithPreRestore(BuildContext context) async {
    final svc = context.read<BackupService>();

    final raw = await svc.pickRawBackupText();
    if (raw == null) return;

    bool isEncrypted = false;
    try {
      final decoded = jsonDecode(raw);
      isEncrypted =
          decoded is Map<String, dynamic> && decoded['encrypted'] == true;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('백업 파일 형식이 올바르지 않습니다.')),
      );
      return;
    }

    String? importPw;
    if (isEncrypted) {
      importPw = await _askPassword(context, title: '백업 비밀번호 입력');
      if (importPw == null || importPw.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('암호화된 백업은 비밀번호가 필요합니다.')),
        );
        return;
      }
    }

    final prePw = await _askPassword(
      context,
      title: '복원 전 자동 백업(PRE-RESTORE) 비밀번호 입력',
    );
    if (prePw == null || prePw.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PRE-RESTORE 자동 백업을 위해 비밀번호가 필요합니다.'),
        ),
      );
      return;
    }

    await svc.safeImportWithPreBackup(
      rawBackupText: raw,
      preBackupPassword: prePw,
      importPassword: importPw,
    );

    await refresh();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 복원 완료')),
    );
  }

  Future<String?> _askPassword(
    BuildContext context, {
    required String title,
  }) async {
    final ctrl = TextEditingController();
    bool obscure = true;

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: ctrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: '비밀번호',
                suffixIcon: IconButton(
                  tooltip: obscure ? '비밀번호 보기' : '비밀번호 숨기기',
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setLocal(() => obscure = !obscure),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      );

      if (ok != true) return null;

      final text = ctrl.text.trim();
      return text.isEmpty ? null : text;
    } finally {
      ctrl.dispose();
    }
  }

  Future<int> createNoteFromScannedText({
    required String body,
    String title = '스캔 가져오기',
  }) async {
    final id = await _data.insertNote(
      title: title,
      body: body,
    );

    await refresh();
    return id;
  }
}

class _NoteCursor {
  final int id;
  final DateTime updatedAt;
  final bool isPinned;

  const _NoteCursor({
    required this.id,
    required this.updatedAt,
    required this.isPinned,
  });
}