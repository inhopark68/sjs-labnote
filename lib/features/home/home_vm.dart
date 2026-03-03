import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/models/note_list_item.dart';
import 'package:labnote/services/backup_service.dart';

/// 홈 화면 상태/로직(ViewModel)
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
  int _page = 0;

  Timer? _searchDebounce;

  // 더미 목록 (화면 확인용)
  late final List<NoteListItem> _all = List.generate(55, (i) {
    final now = DateTime.now();
    return NoteListItem(
      id: 'note_${i + 1}',
      title: '노트 ${i + 1}',
      bodyPreview: '미리보기 내용... (${i + 1})',
      createdAt: now.subtract(Duration(days: i)),
      updatedAt: now.subtract(Duration(hours: i)),
      isPinned: i % 13 == 0,
      isLocked: i % 17 == 0,
      attachmentCount: i % 4,
      reagentCount: i % 7,
      cellCount: i % 3,
      equipmentCount: i % 5,
      hasExpiredReagent: i % 19 == 0,
      hasExpiringSoon: i % 11 == 0,
      tagNames: [
        if (i % 2 == 0) 'PCR',
        if (i % 3 == 0) 'Day${(i % 5) + 1}',
        if (i % 4 == 0) 'Sample-${(i % 8) + 1}',
      ],
    );
  });

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

  Future<void> refresh() async {
    loading = true;
    loadingMore = false;
    hasMore = true;
    _page = 0;
    notifyListeners();

    try {
      final filtered = _applyQuery(_all, query);
      final slice = _pageSlice(filtered, page: _page);

      items
        ..clear()
        ..addAll(slice);

      hasMore = items.length < filtered.length;

      // TODO: 실제 DB 연동 시 _data 사용
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
      final filtered = _applyQuery(_all, query);

      _page += 1;
      final slice = _pageSlice(filtered, page: _page);

      if (slice.isEmpty) {
        hasMore = false;
        return;
      }

      items.addAll(slice);
      hasMore = items.length < filtered.length;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  List<NoteListItem> _applyQuery(List<NoteListItem> src, String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) return src;

    return src.where((n) {
      return n.title.toLowerCase().contains(qq) ||
          n.bodyPreview.toLowerCase().contains(qq) ||
          n.tagNames.any((t) => t.toLowerCase().contains(qq));
    }).toList();
  }

  List<NoteListItem> _pageSlice(List<NoteListItem> src, {required int page}) {
    final start = page * _pageSize;
    if (start >= src.length) return const [];
    final end = (start + _pageSize).clamp(0, src.length);
    return src.sublist(start, end);
  }

  // ----------------------------------------------------------------------
  // Backup actions (BackupService의 실제 API에 맞춤)
  // ----------------------------------------------------------------------

  /// ✅ 간단 백업: 비밀번호 없이(평문) 내보내기
  Future<void> exportBackupPlain(BuildContext context) async {
    final svc = context.read<BackupService>();
    await svc.exportBackup(password: null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('백업 내보내기 완료')));
  }

  /// ✅ 복원: 파일 선택 → 암호화 여부 확인 → (필요시) 비번 입력 → PRE-RESTORE 비번 입력 → 복원
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('백업 파일 형식이 올바르지 않습니다.')));
      return;
    }

    String? importPw;
    if (isEncrypted) {
      importPw = await _askPassword(context, title: '백업 비밀번호 입력');
      if (importPw == null || importPw.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('암호화된 백업은 비밀번호가 필요합니다.')));
        return;
      }
    }

    // PRE-RESTORE 백업 비밀번호(안전장치)
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

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('백업 복원 완료')));
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
