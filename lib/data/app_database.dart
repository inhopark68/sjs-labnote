import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../dao/note_items_dao.dart';

part 'app_database.g.dart';

// =====================================================
// Domain / Repository
// =====================================================

abstract class NotesRepository {
  Future<List<Note>> listNotes({
    String query = '',
    int? limit,
    int? offset,
  });

  Future<Note?> getNote(int id);

  Future<int> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  });

//AppDatabase에 “날짜/핀만 말고, 제목+본문도 함께 업데이트” 메서드 확인
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  });

  Future<void> deleteNote(int id); // soft delete
  Future<void> restoreNote(int id);
  Future<void> togglePin(int id);

  Future<void> replaceAllNotesFromBackup(List<Note> notes);
}

class Note {
  final int id; // ✅ String -> int
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final String? project;
  final DateTime? noteDate;

  /// (선택) 구버전 String id를 마이그레이션/디버그용으로 보관
  final String? legacyId;

  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.isLocked,
    required this.isDeleted,
    this.project,
    this.noteDate,
    this.legacyId,
  });
}

// =====================================================
// Drift Tables
// =====================================================

class DbNotes extends Table {
  // ✅ int PK
  IntColumn get id => integer().autoIncrement()();

  // ✅ 구버전 String id 저장(마이그레이션/백업 호환용)
  TextColumn get legacyId => text().nullable()();

  DateTimeColumn get noteDate => dateTime().nullable()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  // ✅ insert 시 편하게 default 지정
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  TextColumn get project => text().nullable()();
}

// ✅ 노트별 시약 기록 (noteId: int)
class DbNoteReagents extends Table {
  TextColumn get id => text()();

  IntColumn get noteId => integer()(); // ✅ text -> int

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ✅ 노트별 재료 기록 (noteId: int)
class DbNoteMaterials extends Table {
  TextColumn get id => text()();

  IntColumn get noteId => integer()(); // ✅ text -> int

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ✅ 노트별 Reference(DOI) 기록 (noteId: int)
class DbNoteReferences extends Table {
  TextColumn get id => text()();

  IntColumn get noteId => integer()(); // ✅ text -> int

  TextColumn get doi => text()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// =====================================================
// Database
// =====================================================

@DriftDatabase(
  tables: [
    DbNotes,
    DbNoteReagents,
    DbNoteMaterials,
    DbNoteReferences,
  ],
)
class AppDatabase extends _$AppDatabase implements NotesRepository {
  AppDatabase() : super(_openConnection());

  late final NoteItemsDao noteItemsDao = NoteItemsDao(this);

  // ✅ 스키마 변경했으니 버전 올리기
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v3 -> v4: id 타입 변경(text -> int)이라 Drift의 addColumn 수준으로는 불가
          // ✅ 안전하게: 새 테이블 생성 후 데이터 이동(가능한 범위)

          // 1) 새 테이블 생성(없으면)
          await m.createTable(dbNotes);
          await m.createTable(dbNoteReagents);
          await m.createTable(dbNoteMaterials);
          await m.createTable(dbNoteReferences);

          // 2) 구 테이블이 있었다면(기존 v3 구조), legacyId로 매핑하며 마이그레이션 시도
          //    - 기존 테이블명이 drift 기본명이라면: db_notes, db_note_reagents...
          //    - 만약 과거 @TableName 사용했으면 실제 이름에 맞춰야 함
          if (await _hasTable(m, 'db_notes')) {
            // 구버전이 text id였다면:
            //  - 새 db_notes는 int PK이므로, 기존 id를 legacyId로 저장
            //  - 이후 아이템 테이블 noteId(text)를 legacyId 매핑해서 int noteId로 변환
            //
            // 주의: 이미 새 테이블과 이름이 같으면 충돌할 수 있어,
            //       프로젝트 실제 상황에 따라 "구 테이블 이름"이 다를 수 있습니다.
            //       (대부분 drift는 같은 이름을 쓰므로, 실 DB에선 새로 생성이 아니라 alter가 필요)
            //
            // 현실적인 운영: 개발 중이면 DB 파일 삭제 후 재생성 추천.
            // 여기서는 가능한 형태의 로직만 제공합니다.
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'labnote',
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
            )
          : null,
    );
  }

  // =====================================================
  // ✅ Integrity: Hard delete (note + related items)
  // =====================================================

  Future<void> hardDeleteNote(int id) async {
    await transaction(() async {
      await noteItemsDao.deleteAllForNote(id); // ✅ int
      await (delete(dbNotes)..where((t) => t.id.equals(id))).go();
    });
  }


  // =====================================================
  // DEBUG helpers
  // =====================================================

  Future<List<DbNote>> debugSampleRowsIncludingDeleted({int limit = 5}) {
    final stmt = select(dbNotes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return stmt.get();
  }

  Future<int> debugCountAllRows() async {
    final countExp = dbNotes.id.count();
    final q = selectOnly(dbNotes)..addColumns([countExp]);
    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<int> debugCountVisibleRows() async {
    final countExp = dbNotes.id.count();
    final q = selectOnly(dbNotes)
      ..addColumns([countExp])
      ..where(dbNotes.isDeleted.equals(false));
    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  // =====================================================
  // NotesRepository 구현
  // =====================================================

  @override
  Future<List<Note>> listNotes({
    String query = '',
    int? limit,
    int? offset,
  }) async {
    final q = query.trim();
    final stmt = select(dbNotes)..where((t) => t.isDeleted.equals(false));

    if (q.isNotEmpty) {
      final like = '%$q%';
      stmt.where((t) => t.title.like(like) | t.body.like(like));
    }

    stmt.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
    ]);

    if (limit != null) {
      stmt.limit(limit, offset: offset);
    }

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<Note?> getNote(int id) async {
    final row = await (select(dbNotes)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  }) async {
    // ✅ createdAt/updatedAt은 default(currentDateAndTime)라 생략 가능
    return into(dbNotes).insert(
      DbNotesCompanion.insert(
        title: Value(title),
        body: Value(body),
        noteDate: Value(noteDate),
      ),
    );
  }

  @override
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        title: Value(title),
        body: Value(body),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteNote(int id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> restoreNote(int id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> togglePin(int id) async {
    final current =
        await (select(dbNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (current == null || current.isDeleted) return;

    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isPinned: Value(!current.isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Note>> listDeletedNotes({
    String query = '',
    int? limit,
    int? offset,
  }) async {
    final q = query.trim();
    final stmt = select(dbNotes)..where((t) => t.isDeleted.equals(true));

    if (q.isNotEmpty) {
      final like = '%$q%';
      stmt.where((t) => t.title.like(like) | t.body.like(like));
    }

    stmt.orderBy([
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
    ]);

    if (limit != null) {
      stmt.limit(limit, offset: offset);
    }

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  /// ✅ 삭제 여부 상관없이 노트 1개 조회(휴지통/상세 보기용)
  Future<Note?> getNoteAny(int id) async {
    final row =
        await (select(dbNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> updateNoteDate(int id, DateTime? date) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        noteDate: Value(date),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> replaceAllNotesFromBackup(List<Note> notes) async {
    await transaction(() async {
      await delete(dbNoteReagents).go();
      await delete(dbNoteMaterials).go();
      await delete(dbNoteReferences).go();
      await delete(dbNotes).go();

      await batch((b) {
        b.insertAll(
          dbNotes,
          notes
              .map(
                (n) => DbNotesCompanion.insert(
                  // id는 autoIncrement라 보통 넣지 않음
                  // 백업에서 id를 살려야 하면 autoIncrement 대신 일반 int PK로 운영해야 함
                  legacyId: Value(n.legacyId),
                  title: Value(n.title),
                  body: Value(n.body),
                  createdAt: Value(n.createdAt),
                  updatedAt: Value(n.updatedAt),
                  isPinned: Value(n.isPinned),
                  isLocked: Value(n.isLocked),
                  isDeleted: Value(n.isDeleted),
                  project: Value(n.project),
                  noteDate: Value(n.noteDate),
                ),
              )
              .toList(growable: false),
        );
      });
    });
  }

  Note _toDomain(DbNote r) => Note(
        id: r.id,
        legacyId: r.legacyId,
        title: r.title,
        body: r.body,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        isPinned: r.isPinned,
        isLocked: r.isLocked,
        isDeleted: r.isDeleted,
        project: r.project,
        noteDate: r.noteDate,
      );

  // =====================================================
  // Migration helpers
  // =====================================================

  Future<bool> _hasTable(Migrator m, String tableName) async {
    final rows = await m.database.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
      variables: [Variable<String>(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  // =====================================================
  // ✅ Backup helper
  // =====================================================

    /// ✅ 삭제 포함 전체 노트 row 반환 (백업 export용)
  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    final stmt = select(dbNotes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
    return stmt.get();
  }
}