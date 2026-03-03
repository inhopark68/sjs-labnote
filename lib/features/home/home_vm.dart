import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/models/note_list_item.dart';
import 'package:labnote/services/backup_service.dart';

class HomeVm extends ChangeNotifier {
  final AppDatabase _data;

  HomeVm(this._data);

  // UI state
  bool searchVisible = false;
  String query = '';

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;

  final List<NoteListItem> items = [];

  static const int _pageSize = 20;
  int _page = 0;

  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> init() async => refresh();

  void toggleSearch() {
    searchVisible = !searchVisible;
    notifyListeners();
  }

  void setQuery(String v) {
    query = v;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });

    notifyListeners();
  }

  // -------------------------
  // DB pagination
  // -------------------------

  Future<void> refresh() async {
    loading = true;
    loadingMore = false;
    hasMore = true;
    _page = 0;
    notifyListeners();

    try {
      // ✅ pageSize+1 로 hasMore 판정
      final fetched = await _data.listNotes(
        query: query.trim(),
        limit: _pageSize + 1,
        offset: 0,
      );

      hasMore = fetched.length > _pageSize;

      final pageNotes = fetched.take(_pageSize);
      final pageItems = pageNotes.map(_toListItem).toList(growable: false);

      items
        ..clear()
        ..addAll(pageItems);
    } catch (e, st) {
      debugPrint('HomeVm.refresh failed: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final nextPage = _page + 1;

      final fetched = await _data.listNotes(
        query: query.trim(),
        limit: _pageSize + 1,
        offset: nextPage * _pageSize,
      );

      final more = fetched.take(_pageSize).map(_toListItem).toList(growable: false);
      items.addAll(more);

      _page = nextPage;
      hasMore = fetched.length > _pageSize;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  // -------------------------
  // Note -> NoteListItem
  // -------------------------

  String _preview(String body) {
    final s = body.replaceAll('\n', ' ').trim();
    return s.length <= 80 ? s : '${s.substring(0, 80)}…';
  }

  NoteListItem _toListItem(Note n) {
    return NoteListItem(
      id: n.id,
      title: n.title,
      bodyPreview: _preview(n.body),
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
        if (n.project != null && n.project!.trim().isNotEmpty) n.project!.trim(),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // Backup actions
  // ----------------------------------------------------------------------

  Future<void> exportBackupPlain(BuildContext context) async {
    final svc = context.read<BackupService>();
    await svc.exportBackup(password: null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('백업 내보내기 완료')));
  }

  Future<void> importBackupWithPreRestore(BuildContext context) async {
    final svc = context.read<BackupService>();

    final raw = await svc.pickRawBackupText();
    if (raw == null) return;

    bool isEncrypted = false;
    try {
      final decoded = jsonDecode(raw);
      isEncrypted = decoded is Map<String, dynamic> && decoded['encrypted'] == true;
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
        const SnackBar(content: Text('PRE-RESTORE 자동 백업을 위해 비밀번호가 필요합니다.')),
      );
      return;
    }

    await svc.safeImportWithPreBackup(
      rawBackupText: raw,
      preBackupPassword: prePw,
      importPassword: importPw,
    );

    // ✅ 복원 후 홈 리스트 갱신
    await refresh();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('백업 복원 완료')));
  }

  Future<String?> _askPassword(
    BuildContext context, {
    required String title,
  }) async {
    final ctrl = TextEditingController();
    bool obscure = true;

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
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
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
    return ctrl.text.trim();
  }
}