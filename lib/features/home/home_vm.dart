import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:labnote/data/database/app_database.dart';
import 'package:labnote/models/note_list_item.dart';
import 'package:labnote/utils/note_text_plain.dart';

class HomeVm extends ChangeNotifier {
  HomeVm(this._data);

  final AppDatabase _data;

  bool searchVisible = false;
  String query = '';

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;

  final List<NoteListItem> items = [];

  static const int _pageSize = 20;

  Timer? _searchDebounce;
  int _requestToken = 0;
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

  String _todayString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _prependAutoMeta({
    required String experimentTag,
    required String body,
  }) {
    return '''
#$experimentTag
#Experiment

$body
''';
  }

  String _stripMetaTagsForPreview(String text) {
    final lines = text.split('\n');

    final filtered = <String>[];
    bool previousWasEmpty = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('#')) {
        continue;
      }

      if (trimmed.isEmpty) {
        if (previousWasEmpty) continue;
        previousWasEmpty = true;
        filtered.add('');
        continue;
      }

      previousWasEmpty = false;
      filtered.add(line);
    }

    return filtered.join('\n').trim();
  }

  List<String> _extractHashTags(String text) {
    final lines = text.split('\n');
    final tags = <String>[];
    final seen = <String>{};

    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('#')) continue;

      final raw = trimmed.substring(1).trim();
      if (raw.isEmpty) continue;

      if (seen.add(raw)) {
        tags.add(raw);
      }
    }

    tags.sort((a, b) {
      if (a == 'Experiment') return 1;
      if (b == 'Experiment') return -1;
      return 0;
    });

    return tags;
  }

  Future<int> insertPlainNoteAndReturnId() async {
    final id = await _data.insertNote(
      title: '',
      body: '',
    );

    await refresh();
    return id;
  }

  Future<int> _insertTemplateNote({
    required String title,
    required String body,
  }) async {
    final id = await _data.insertNote(
      title: title,
      body: body,
    );

    await refresh();
    return id;
  }

  Future<int> insertWesternBlotNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'WesternBlot',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target protein:
- comparison group:
- hypothesis:

샘플 정보
- sample:
- cell/tissue type:
- treatment condition:
- collection time:
- biological replicate:
- technical replicate:

단백질 추출 / 정량
- lysis buffer:
- inhibitor:
- quantification method:
- protein concentration:
- loading amount (ug):
- sample buffer:
- heating condition:

Gel / Transfer
- gel %:
- running buffer:
- running condition:
- membrane type:
- transfer buffer:
- transfer condition:
- transfer temperature:

Blocking
- blocking buffer:
- blocking time:
- blocking temperature:

1차 항체
- antibody:
- company:
- catalog no:
- host:
- dilution:
- buffer:
- incubation time:
- incubation temperature:

세척
- wash buffer:
- wash count:
- wash time:

2차 항체
- antibody:
- company:
- dilution:
- buffer:
- incubation time:
- incubation temperature:

Lane 배치
| Lane | Sample | Amount(ug) | Note |
|------|--------|------------|------|
| 1 | Marker |  |  |
| 2 | Control |  |  |
| 3 | Sample 1 |  |  |
| 4 | Sample 2 |  |  |
| 5 | Sample 3 |  |  |
| 6 | Positive control |  |  |
| 7 | Negative control |  |  |

검출
- detection reagent:
- imaging system:
- exposure time:
- file name:

결과
- expected size (kDa):
- observed band:
- band intensity:
- loading control:
- background:
- nonspecific bands:

정량 분석
- software:
- normalization:
- relative expression:

해석
- 

문제점 / 트러블슈팅
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'Western Blot',
      body: template,
    );
  }

  Future<int> insertRtPcrNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'RTPCR',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target gene:
- comparison group:
- hypothesis:

샘플 정보
- sample:
- cell/tissue type:
- treatment condition:
- collection time:
- biological replicate:
- technical replicate:

RNA 추출
- extraction method:
- kit/reagent:
- RNA concentration:
- A260/A280:
- RNA quality:

cDNA 합성
- reverse transcription kit:
- input RNA amount:
- reaction volume:
- reaction condition:

Primer 정보
- target primer:
- forward sequence:
- reverse sequence:
- housekeeping gene:
- primer company:

qPCR 조건
- master mix:
- machine:
- total volume:
- annealing temperature:
- cycle condition:

Plate 배치
| Well | Sample | Target | Replicate | Note |
|------|--------|--------|-----------|------|
| A1 | Control |  | 1 |  |
| A2 | Control |  | 2 |  |
| A3 | Sample 1 |  | 1 |  |
| A4 | Sample 1 |  | 2 |  |
| A5 | Sample 2 |  | 1 |  |
| A6 | Sample 2 |  | 2 |  |
| A7 | NTC |  | 1 |  |
| A8 | Positive control |  | 1 |  |

결과
- Ct(target):
- Ct(reference):
- delta Ct:
- delta delta Ct:
- relative expression:

해석
- 

문제점 / 트러블슈팅
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'RT-PCR',
      body: template,
    );
  }

  Future<int> insertIfNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'IF',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target:
- sample:
- hypothesis:

샘플 정보
- cell/tissue:
- seeding density:
- treatment:
- fixation time:

고정 / 투과화 / blocking
- fixative:
- fixation time:
- permeabilization buffer:
- permeabilization time:
- blocking buffer:
- blocking time:

1차 항체
- antibody:
- company:
- catalog no:
- host:
- dilution:
- incubation time:
- incubation temperature:

2차 항체
- antibody:
- fluorophore:
- company:
- dilution:
- incubation time:
- light protection:

핵 염색 / mounting
- nuclear stain:
- mounting medium:

이미징
- microscope:
- objective:
- exposure:
- channel:
- file name:

결과
- signal location:
- signal intensity:
- background:
- nonspecific staining:
- merged image summary:

해석
- 

문제점 / 트러블슈팅
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'IF',
      body: template,
    );
  }

  Future<int> insertIhcNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'IHC',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target:
- tissue:
- hypothesis:

샘플 정보
- tissue type:
- block/sample id:
- section thickness:
- slide count:

전처리
- deparaffinization:
- rehydration:
- antigen retrieval buffer:
- antigen retrieval condition:
- endogenous peroxidase blocking:

Blocking
- blocking reagent:
- blocking time:

1차 항체
- antibody:
- company:
- catalog no:
- host:
- dilution:
- incubation time:
- incubation temperature:

2차 항체 / 검출
- secondary antibody:
- detection system:
- chromogen:
- reaction time:

Counterstain / Mounting
- counterstain:
- dehydration:
- mounting medium:

이미징
- microscope/scanner:
- magnification:
- file name:

결과
- staining location:
- staining intensity:
- positive area:
- background:
- nonspecific staining:

해석
- 

문제점 / 트러블슈팅
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'IHC',
      body: template,
    );
  }

  Future<int> insertElisaNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'ELISA',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target protein:
- hypothesis:

샘플 정보
- sample type:
- treatment:
- replicate:

Plate 정보
- plate type:
- coating antibody:
- blocking buffer:

샘플 처리
- sample dilution:
- incubation time:

Detection antibody
- antibody:
- company:
- dilution:

Substrate
- substrate type:
- reaction time:

Plate reader
- wavelength:

Plate 배치
| Well | Content | Dilution | Replicate | Note |
|------|---------|----------|-----------|------|
| A1 | Blank |  | 1 |  |
| A2 | Standard 1 |  | 1 |  |
| A3 | Standard 2 |  | 1 |  |
| A4 | Standard 3 |  | 1 |  |
| A5 | Sample 1 |  | 1 |  |
| A6 | Sample 1 |  | 2 |  |
| A7 | Sample 2 |  | 1 |  |
| A8 | Sample 2 |  | 2 |  |

결과
- OD values:
- standard curve:
- concentration calculation:

해석
- 

문제점
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'ELISA',
      body: template,
    );
  }

  Future<int> insertFacsNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'FACS',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

실험 목적
- target marker:
- hypothesis:

샘플 정보
- cell type:
- treatment condition:
- cell count:

Staining
- antibody:
- fluorophore:
- company:
- dilution:

Controls
- unstained control
- single stain control
- FMO control

Instrument
- machine:
- laser configuration:

Acquisition
- events collected:

Analysis
- gating strategy:
- population percentage:

결과
- 

해석
- 

문제점
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'FACS',
      body: template,
    );
  }

  Future<int> insertCellCultureNoteAndReturnId() {
    final template = _prependAutoMeta(
      experimentTag: 'CellCulture',
      body: '''
실험 날짜
- ${_todayString()}

실험자
- 

세포 정보
- cell line:
- passage number:
- source:

배양 조건
- medium:
- serum:
- antibiotics:

배양 환경
- CO2:
- temperature:
- humidity:

Seeding
- seeding density:
- plate type:

처리 조건
- treatment:
- concentration:
- treatment time:

관찰
- morphology:
- confluency:
- contamination 여부:

결과
- 

문제점
- 

다음 계획
- 
''',
    );

    return _insertTemplateNote(
      title: 'Cell Culture',
      body: template,
    );
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

  void setQuery(String value) {
    if (query == value) return;

    query = value;
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
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }

      final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
      if (updatedCompare != 0) return updatedCompare;

      return b.id.compareTo(a.id);
    });
  }

  NoteListItem _toListItem(NoteListRow row) {
    final project = row.project?.trim();
    final previewPlain = noteStoredTextToPlain(row.preview);
    final cleanedPreview = _stripMetaTagsForPreview(previewPlain);
    final extractedTags = _extractHashTags(previewPlain);

    return NoteListItem(
      id: row.id,
      title: noteStoredTextToPlain(row.title),
      bodyPreview: cleanedPreview,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isPinned: row.isPinned,
      isLocked: row.isLocked,
      attachmentCount: 0,
      reagentCount: 0,
      cellCount: 0,
      equipmentCount: 0,
      hasExpiredReagent: false,
      hasExpiringSoon: false,
      tagNames: [
        ...extractedTags,
        if (project != null && project.isNotEmpty) project,
      ],
    );
  }
}

class _NoteCursor {
  const _NoteCursor({
    required this.id,
    required this.updatedAt,
    required this.isPinned,
  });

  final int id;
  final DateTime updatedAt;
  final bool isPinned;
}