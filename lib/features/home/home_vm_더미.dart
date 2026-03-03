import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ DB (현재는 주입만 받고, TODO로 실제 연동 예정)
import 'package:labnote/data/app_database.dart';

// ✅ 홈 리스트에 표시할 “UI 전용 모델”(제목/미리보기/태그/카운트 등)
import 'package:labnote/models/note_list_item.dart';

// ✅ 백업/복원 기능(플랫폼 I/O + 암호화 등은 서비스가 처리)
import 'package:labnote/services/backup_service.dart';

/// 홈 화면 상태/로직(ViewModel)
/// - HomeScreen(뷰)은 그리기만 하고
/// - HomeVm(뷰모델)은 상태 + 액션 + 데이터 가공을 담당
class HomeVm extends ChangeNotifier {
  /// 실제 DB (향후 더미 대신 DB에서 목록을 가져올 때 사용)
  final AppDatabase _data;

  HomeVm(this._data);

  // ----------------------------------------------------------------------
  // UI state (화면 상태)
  // ----------------------------------------------------------------------

  /// 검색창 표시 여부
  bool searchVisible = false;

  /// 검색어
  String query = '';

  /// 전체 새로고침 로딩 중인지
  bool loading = false;

  /// 스크롤 “더 불러오기” 로딩 중인지
  bool loadingMore = false;

  /// 더 불러올 항목이 있는지
  bool hasMore = true;

  /// 현재 화면에 보여줄 노트 목록(표시용)
  final List<NoteListItem> items = [];

  // ----------------------------------------------------------------------
  // Pagination (페이지네이션)
  // ----------------------------------------------------------------------

  /// 한 번에 로드할 개수
  static const int _pageSize = 20;

  /// 현재 페이지(0부터 시작)
  int _page = 0;

  /// 검색 입력 디바운스 타이머(타이핑할 때마다 refresh를 바로 하지 않도록)
  Timer? _searchDebounce;

  // ----------------------------------------------------------------------
  // Dummy data (현재 화면 확인용 더미 목록)
  // - 실제 DB 연동이 되면 이 _all을 없애고 _data에서 가져오도록 바꿀 예정
  // ----------------------------------------------------------------------

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
    // 디바운스 타이머 정리(메모리/호출 누수 방지)
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// 홈 화면에서 최초로 한 번 호출하는 초기화 함수
  /// - 현재는 목록 새로고침만 수행
  Future<void> init() async => refresh();

  // ----------------------------------------------------------------------
  // UI actions (버튼/입력 이벤트에 대응)
  // ----------------------------------------------------------------------

  /// 검색창 열기/닫기 토글
  void toggleSearch() {
    searchVisible = !searchVisible;
    notifyListeners();
  }

  /// 검색어 설정
  /// - 사용자가 타이핑할 때마다 즉시 refresh를 때리면 부담이 크므로
  ///   300ms 디바운스 후 refresh() 수행
  void setQuery(String v) {
    query = v;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      refresh();
    });

    // 검색어 UI(텍스트) 변경을 반영하기 위해 notify
    notifyListeners();
  }

  // ----------------------------------------------------------------------
  // Data loading (리스트 로딩/갱신/더보기)
  // ----------------------------------------------------------------------

  /// 첫 페이지부터 다시 로드(검색 적용 포함)
  Future<void> refresh() async {
    loading = true;
    loadingMore = false;
    hasMore = true;
    _page = 0;
    notifyListeners();

    try {
      // 1) 검색 적용
      final filtered = _applyQuery(_all, query);

      // 2) 첫 페이지 slice
      final slice = _pageSlice(filtered, page: _page);

      // 3) 화면 목록 갱신
      items
        ..clear()
        ..addAll(slice);

      // 4) 더보기 여부 계산
      hasMore = items.length < filtered.length;

      // TODO: 실제 DB 연동 시 _data 사용
      // 예) final notes = await _data.listNotes(query: query);
      //     items..clear()..addAll(notesToListItem(notes));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지를 추가 로드(무한 스크롤용)
  Future<void> loadMore() async {
    // 중복 호출 방지
    if (loading || loadingMore || !hasMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final filtered = _applyQuery(_all, query);

      // 다음 페이지로 이동
      _page += 1;

      // 다음 페이지 slice
      final slice = _pageSlice(filtered, page: _page);

      // 더 이상 없으면 종료
      if (slice.isEmpty) {
        hasMore = false;
        return;
      }

      // 리스트 뒤에 이어붙이기
      items.addAll(slice);

      // 더보기 여부 갱신
      hasMore = items.length < filtered.length;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  // ----------------------------------------------------------------------
  // Filtering / Paging helpers
  // ----------------------------------------------------------------------

  /// query를 적용해 필터링(제목/미리보기/태그 기준)
  List<NoteListItem> _applyQuery(List<NoteListItem> src, String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) return src;

    return src.where((n) {
      return n.title.toLowerCase().contains(qq) ||
          n.bodyPreview.toLowerCase().contains(qq) ||
          n.tagNames.any((t) => t.toLowerCase().contains(qq));
    }).toList();
  }

  /// 페이지 번호에 해당하는 구간만 잘라 반환
  List<NoteListItem> _pageSlice(List<NoteListItem> src, {required int page}) {
    final start = page * _pageSize;
    if (start >= src.length) return const [];
    final end = (start + _pageSize).clamp(0, src.length);
    return src.sublist(start, end);
  }

  // ----------------------------------------------------------------------
  // Backup actions (BackupService의 실제 API에 맞춤)
  // - HomeScreen에서 버튼 클릭 시 호출되는 액션들
  // ----------------------------------------------------------------------

  /// ✅ 간단 백업: 비밀번호 없이(평문) 내보내기
  /// - exportBackup(password: null) 호출
  /// - 완료 시 스낵바 표시
  Future<void> exportBackupPlain(BuildContext context) async {
    final svc = context.read<BackupService>();
    await svc.exportBackup(password: null);

    // async 이후 context 유효성 확인
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 내보내기 완료')),
    );
  }

  /// ✅ 복원: 파일 선택 → 암호화 여부 확인 → (필요시) 비번 입력
  ///       → PRE-RESTORE 비번 입력 → safeImportWithPreBackup 실행
  Future<void> importBackupWithPreRestore(BuildContext context) async {
    final svc = context.read<BackupService>();

    // 1) 사용자가 백업 파일(텍스트)을 선택
    final raw = await svc.pickRawBackupText();
    if (raw == null) return;

    // 2) 암호화 여부 판별(encrypted: true)
    bool isEncrypted = false;
    try {
      final decoded = jsonDecode(raw);
      isEncrypted = decoded is Map<String, dynamic> && decoded['encrypted'] == true;
    } catch (_) {
      // JSON 파싱 자체가 안 되면 백업 형식 문제
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('백업 파일 형식이 올바르지 않습니다.')),
      );
      return;
    }

    // 3) 암호화된 백업이면 import 비번 입력 받기
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

    // 4) 안전장치: 복원 전 자동 백업(PRE-RESTORE)에 쓸 비번 받기
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

    // 5) 서비스에 맡겨서:
    //    - 현재 데이터 PRE-RESTORE로 자동 백업(항상 암호화)
    //    - 선택한 백업 복원(전체 교체)
    await svc.safeImportWithPreBackup(
      rawBackupText: raw,
      preBackupPassword: prePw,
      importPassword: importPw,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('백업 복원 완료')),
    );
  }

  // ----------------------------------------------------------------------
  // UI helper: 비밀번호 입력 다이얼로그
  // ----------------------------------------------------------------------

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