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

  Future<Note?> getNote(String id);

  Future<String> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  });

  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
  });

  Future<void> deleteNote(String id); // soft delete
  Future<void> restoreNote(String id);
  Future<void> togglePin(String id);

  Future<void> replaceAllNotesFromBackup(List<Note> notes);
}

class Note {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final bool isDeleted;
  final String? project;
  final DateTime? noteDate;

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
  });
}

// =====================================================
// Drift Tables
// =====================================================

class DbNotes extends Table {
  TextColumn get id => text()();

  DateTimeColumn get noteDate => dateTime().nullable()();

  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  TextColumn get project => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ✅ 노트별 시약 기록
class DbNoteReagents extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ✅ 노트별 재료 기록
class DbNoteMaterials extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();

  TextColumn get name => text()();
  TextColumn get catalogNumber => text().nullable()();
  TextColumn get lotNumber => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ✅ 노트별 Reference(DOI) 기록
class DbNoteReferences extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text()();

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

  // ✅ 방식 A: AppDatabase가 DAO를 생성해 제공
  late final NoteItemsDao noteItemsDao = NoteItemsDao(this);

  @override
  int get schemaVersion => 3;

  // ✅ 요청대로: addColumn 없는 onCreate만
  // 웹에서는 IndexedDB를 삭제해서 초기화하는 방식
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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

  /// ✅ 노트를 '완전 삭제'할 때만 사용 (관련 시약/재료/DOI도 함께 삭제)
  Future<void> hardDeleteNote(String id) async {
    await transaction(() async {
      await noteItemsDao.deleteAllForNote(id);
      await (delete(dbNotes)..where((t) => t.id.equals(id))).go();
    });
  }

  // -------------------------
  // DEBUG helpers
  // -------------------------

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

  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    return select(dbNotes).get();
  }

  // -------------------------
  // NotesRepository 구현
  // -------------------------

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
  Future<Note?> getNote(String id) async {
    final row = await (select(dbNotes)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();

    return row == null ? null : _toDomain(row);
  }

  @override
  Future<String> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  }) async {
    final now = DateTime.now();
    final id = _newId();

    await into(dbNotes).insert(
      DbNotesCompanion.insert(
        id: id,
        title: Value(title),
        body: Value(body),
        createdAt: now,
        updatedAt: now,
        noteDate: Value(noteDate),
      ),
    );

    return id;
  }

  @override
  Future<void> updateNote({
    required String id,
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
  Future<void> deleteNote(String id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> restoreNote(String id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> togglePin(String id) async {
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

  /// ✅ 휴지통(삭제된 노트) 목록
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
  Future<Note?> getNoteAny(String id) async {
    final row =
        await (select(dbNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }


  Future<void> updateNoteDate(String id, DateTime? date) async {
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
      await delete(dbNotes).go();

      await batch((b) {
        b.insertAll(
          dbNotes,
          notes
              .map(
                (n) => DbNotesCompanion.insert(
                  id: n.id,
                  title: Value(n.title),
                  body: Value(n.body),
                  createdAt: n.createdAt,
                  updatedAt: n.updatedAt,
                  isPinned: Value(n.isPinned),
                  isLocked: Value(n.isLocked),
                  isDeleted: Value(n.isDeleted),
                  project: Value(n.project),
                  noteDate: Value(n.noteDate),
                ),
              )
              .toList(growable: false),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Note _toDomain(DbNote r) => Note(
        id: r.id,
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

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}