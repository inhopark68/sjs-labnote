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

  /// 구버전 String id 보관
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

  /// 구버전 text id 저장
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
          await customStatement('PRAGMA foreign_keys = OFF;');
          try {
            if (from < 4) {
              await _migrateV3TextIdToV4IntId(m);
            }
          } finally {
            await customStatement('PRAGMA foreign_keys = ON;');
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
  // Auto migration: v3(text id) -> v4(int id)
  // =====================================================

  Future<void> _migrateV3TextIdToV4IntId(Migrator m) async {
    final hasNotes = await _hasTable('db_notes');
    if (!hasNotes) {
      await m.createAll();
      return;
    }

    final idType = await _columnType('db_notes', 'id');
    final alreadyMigrated =
        idType != null && idType.toUpperCase().contains('INT');

    if (alreadyMigrated) {
      await _createMissingTablesIfNeeded(m);
      return;
    }

    final hasReagents = await _hasTable('db_note_reagents');
    final hasMaterials = await _hasTable('db_note_materials');
    final hasReferences = await _hasTable('db_note_references');

    await customStatement('ALTER TABLE db_notes RENAME TO db_notes_old;');

    if (hasReagents) {
      await customStatement(
        'ALTER TABLE db_note_reagents RENAME TO db_note_reagents_old;',
      );
    }
    if (hasMaterials) {
      await customStatement(
        'ALTER TABLE db_note_materials RENAME TO db_note_materials_old;',
      );
    }
    if (hasReferences) {
      await customStatement(
        'ALTER TABLE db_note_references RENAME TO db_note_references_old;',
      );
    }

    await m.createAll();

    await customStatement('''
      CREATE TEMP TABLE note_id_map (
        legacy_id TEXT PRIMARY KEY,
        new_id INTEGER NOT NULL
      );
    ''');

    final hasLegacyIdCol = await _hasColumn('db_notes_old', 'legacy_id');
    final hasNoteDateCol = await _hasColumn('db_notes_old', 'note_date');
    final hasProjectCol = await _hasColumn('db_notes_old', 'project');
    final hasIsPinnedCol = await _hasColumn('db_notes_old', 'is_pinned');
    final hasIsLockedCol = await _hasColumn('db_notes_old', 'is_locked');
    final hasIsDeletedCol = await _hasColumn('db_notes_old', 'is_deleted');
    final hasCreatedAtCol = await _hasColumn('db_notes_old', 'created_at');
    final hasUpdatedAtCol = await _hasColumn('db_notes_old', 'updated_at');

    final legacyIdExpr = hasLegacyIdCol ? 'legacy_id' : 'id';
    final noteDateExpr = hasNoteDateCol ? 'note_date' : 'NULL';
    final projectExpr = hasProjectCol ? 'project' : 'NULL';
    final isPinnedExpr = hasIsPinnedCol ? 'COALESCE(is_pinned, 0)' : '0';
    final isLockedExpr = hasIsLockedCol ? 'COALESCE(is_locked, 0)' : '0';
    final isDeletedExpr = hasIsDeletedCol ? 'COALESCE(is_deleted, 0)' : '0';
    final createdAtExpr = hasCreatedAtCol
        ? 'COALESCE(created_at, CURRENT_TIMESTAMP)'
        : 'CURRENT_TIMESTAMP';
    final updatedAtExpr = hasUpdatedAtCol
        ? 'COALESCE(updated_at, $createdAtExpr)'
        : createdAtExpr;

    await customStatement('''
      INSERT INTO db_notes (
        legacy_id,
        note_date,
        title,
        body,
        created_at,
        updated_at,
        is_pinned,
        is_locked,
        is_deleted,
        project
      )
      SELECT
        $legacyIdExpr,
        $noteDateExpr,
        COALESCE(title, ''),
        COALESCE(body, ''),
        $createdAtExpr,
        $updatedAtExpr,
        $isPinnedExpr,
        $isLockedExpr,
        $isDeletedExpr,
        $projectExpr
      FROM db_notes_old
      ORDER BY
        CASE WHEN $createdAtExpr IS NULL THEN 1 ELSE 0 END,
        $createdAtExpr ASC,
        rowid ASC;
    ''');

    await customStatement('''
      INSERT INTO note_id_map (legacy_id, new_id)
      SELECT legacy_id, id
      FROM db_notes
      WHERE legacy_id IS NOT NULL;
    ''');

    if (hasReagents) {
      final reagentHasCatalog = await _hasColumn(
        'db_note_reagents_old',
        'catalog_number',
      );
      final reagentHasLot = await _hasColumn(
        'db_note_reagents_old',
        'lot_number',
      );
      final reagentHasCompany = await _hasColumn(
        'db_note_reagents_old',
        'company',
      );
      final reagentHasMemo = await _hasColumn(
        'db_note_reagents_old',
        'memo',
      );
      final reagentHasCreatedAt = await _hasColumn(
        'db_note_reagents_old',
        'created_at',
      );

      await customStatement('''
        INSERT INTO db_note_reagents (
          id,
          note_id,
          name,
          catalog_number,
          lot_number,
          company,
          memo,
          created_at
        )
        SELECT
          r.id,
          m.new_id,
          COALESCE(r.name, ''),
          ${reagentHasCatalog ? 'r.catalog_number' : 'NULL'},
          ${reagentHasLot ? 'r.lot_number' : 'NULL'},
          ${reagentHasCompany ? 'r.company' : 'NULL'},
          ${reagentHasMemo ? 'r.memo' : 'NULL'},
          ${reagentHasCreatedAt ? 'COALESCE(r.created_at, CURRENT_TIMESTAMP)' : 'CURRENT_TIMESTAMP'}
        FROM db_note_reagents_old r
        INNER JOIN note_id_map m
          ON m.legacy_id = r.note_id;
      ''');
    }

    if (hasMaterials) {
      final materialHasCatalog = await _hasColumn(
        'db_note_materials_old',
        'catalog_number',
      );
      final materialHasLot = await _hasColumn(
        'db_note_materials_old',
        'lot_number',
      );
      final materialHasCompany = await _hasColumn(
        'db_note_materials_old',
        'company',
      );
      final materialHasMemo = await _hasColumn(
        'db_note_materials_old',
        'memo',
      );
      final materialHasCreatedAt = await _hasColumn(
        'db_note_materials_old',
        'created_at',
      );

      await customStatement('''
        INSERT INTO db_note_materials (
          id,
          note_id,
          name,
          catalog_number,
          lot_number,
          company,
          memo,
          created_at
        )
        SELECT
          r.id,
          m.new_id,
          COALESCE(r.name, ''),
          ${materialHasCatalog ? 'r.catalog_number' : 'NULL'},
          ${materialHasLot ? 'r.lot_number' : 'NULL'},
          ${materialHasCompany ? 'r.company' : 'NULL'},
          ${materialHasMemo ? 'r.memo' : 'NULL'},
          ${materialHasCreatedAt ? 'COALESCE(r.created_at, CURRENT_TIMESTAMP)' : 'CURRENT_TIMESTAMP'}
        FROM db_note_materials_old r
        INNER JOIN note_id_map m
          ON m.legacy_id = r.note_id;
      ''');
    }

    if (hasReferences) {
      final refHasMemo = await _hasColumn(
        'db_note_references_old',
        'memo',
      );
      final refHasCreatedAt = await _hasColumn(
        'db_note_references_old',
        'created_at',
      );

      await customStatement('''
        INSERT INTO db_note_references (
          id,
          note_id,
          doi,
          memo,
          created_at
        )
        SELECT
          r.id,
          m.new_id,
          COALESCE(r.doi, ''),
          ${refHasMemo ? 'r.memo' : 'NULL'},
          ${refHasCreatedAt ? 'COALESCE(r.created_at, CURRENT_TIMESTAMP)' : 'CURRENT_TIMESTAMP'}
        FROM db_note_references_old r
        INNER JOIN note_id_map m
          ON m.legacy_id = r.note_id;
      ''');
    }

    final oldCount = await _countRows('db_notes_old');
    final newCount = await _countRows('db_notes');

    if (oldCount != newCount) {
      throw StateError(
        'db_notes migration row count mismatch: old=$oldCount new=$newCount',
      );
    }

    await customStatement('DROP TABLE IF EXISTS db_notes_old;');
    await customStatement('DROP TABLE IF EXISTS db_note_reagents_old;');
    await customStatement('DROP TABLE IF EXISTS db_note_materials_old;');
    await customStatement('DROP TABLE IF EXISTS db_note_references_old;');
    await customStatement('DROP TABLE IF EXISTS note_id_map;');
  }

  Future<void> _createMissingTablesIfNeeded(Migrator m) async {
    if (!await _hasTable('db_notes')) {
      await m.createTable(dbNotes);
    }
    if (!await _hasTable('db_note_reagents')) {
      await m.createTable(dbNoteReagents);
    }
    if (!await _hasTable('db_note_materials')) {
      await m.createTable(dbNoteMaterials);
    }
    if (!await _hasTable('db_note_references')) {
      await m.createTable(dbNoteReferences);
    }
  }

  // =====================================================
  // Integrity: Hard delete
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
  // NotesRepository
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
  // Schema helpers
  // =====================================================

  Future<bool> _hasTable(String tableName) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
      variables: [Variable<String>(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<bool> _hasColumn(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName);').get();
    for (final row in rows) {
      final name = row.data['name']?.toString();
      if (name == columnName) return true;
    }
    return false;
  }

  Future<String?> _columnType(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName);').get();
    for (final row in rows) {
      final name = row.data['name']?.toString();
      if (name == columnName) {
        return row.data['type']?.toString();
      }
    }
    return null;
  }

  Future<int> _countRows(String tableName) async {
    final rows = await customSelect(
      'SELECT COUNT(*) AS c FROM $tableName;',
    ).get();
    if (rows.isEmpty) return 0;
    final value = rows.first.data['c'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}