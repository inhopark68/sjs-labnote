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
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final String? project;
  final DateTime? noteDate;

  /// 구버전 String id를 마이그레이션/디버그용으로 보관
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
  IntColumn get id => integer().autoIncrement()();

  /// 구버전 String id 저장(마이그레이션/백업 호환용)
  TextColumn get legacyId => text().nullable()();

  DateTimeColumn get noteDate => dateTime().nullable()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  TextColumn get project => text().nullable()();
}

class DbNoteReagents extends Table {
  TextColumn get id => text()();
  IntColumn get noteId => integer()();

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DbNoteMaterials extends Table {
  TextColumn get id => text()();
  IntColumn get noteId => integer()();

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class DbNoteReferences extends Table {
  TextColumn get id => text()();
  IntColumn get noteId => integer()();

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

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // 주의:
          // v3 -> v4에서 id 타입이 text -> int로 변경되었기 때문에
          // 실제 운영 DB에서는 별도 테이블 재구성/데이터 이관이 필요할 수 있습니다.
          //
          // 현재 코드는 "개발 중이거나 새로 설치되는 환경"을 기준으로 안전하게 유지하는 형태입니다.
          // 이미 운영 중인 기존 DB를 완전 자동 이관해야 한다면,
          // old table rename -> new table create -> data copy 전략을 별도로 작성해야 합니다.

          if (from < 4) {
            // 개발 중 일부 환경에서 누락된 테이블이 있으면 생성
            await m.createTable(dbNotes);
            await m.createTable(dbNoteReagents);
            await m.createTable(dbNoteMaterials);
            await m.createTable(dbNoteReferences);
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
  // Integrity: Hard delete (note + related items)
  // =====================================================

  Future<void> hardDeleteNote(int id) async {
    await transaction(() async {
      await noteItemsDao.deleteAllForNote(id);
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
      stmt.where((t) => (t.title.like(like) | t.body.like(like)));
    }

    stmt.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
    ]);

    if (limit != null) {
      stmt.limit(limit, offset: offset ?? 0);
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

  Future<Note?> getNoteAny(int id) async {
    final row =
        await (select(dbNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  }) {
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

  Future<void> updateNoteDate(int id, DateTime? date) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        noteDate: Value(date),
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
      stmt.where((t) => (t.title.like(like) | t.body.like(like)));
    }

    stmt.orderBy([
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
    ]);

    if (limit != null) {
      stmt.limit(limit, offset: offset ?? 0);
    }

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
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

  // =====================================================
  // Backup helper
  // =====================================================

  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    final stmt = select(dbNotes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);

    return stmt.get();
  }

  // =====================================================
  // Mapping
  // =====================================================

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
}