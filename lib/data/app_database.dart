import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dao/note_items_dao.dart';

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

  Future<List<Note>> listNotesFirstPage({
    required String query,
    required int limit,
  });

  Future<List<Note>> listNotesAfterCursor({
    required String query,
    required int limit,
    required DateTime lastUpdatedAt,
    required int lastId,
    required bool lastIsPinned,
  });

  Future<List<NoteListRow>> listNoteRowsFirstPage({
    required String query,
    required int limit,
  });

  Future<List<NoteListRow>> listNoteRowsAfterCursor({
    required String query,
    required int limit,
    required DateTime lastUpdatedAt,
    required int lastId,
    required bool lastIsPinned,
  });

  Future<Note?> getNote(int id);

  Future<int> insertNote({
    required String title,
    required String body,
    DateTime? noteDate,
  });

  Future<void> updateNoteContent(
    int noteId, {
    required String title,
    required String body,
  });

  Future<void> deleteNote(int id);
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

class NoteListRow {
  final int id;
  final String title;
  final String preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final String? project;

  NoteListRow({
    required this.id,
    required this.title,
    required this.preview,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.isLocked,
    required this.project,
  });
}

class FigureRow {
  final int id;
  final String title;
  final String? description;
  final String? project;
  final String layoutType;
  final String? caption;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int panelCount;

  FigureRow({
    required this.id,
    required this.title,
    required this.description,
    required this.project,
    required this.layoutType,
    required this.caption,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.panelCount,
  });
}

class FigurePanelRow {
  final int id;
  final int figureId;
  final String panelLabel;
  final String? title;
  final String? caption;
  final int? sourceNoteId;
  final int? sourceAttachmentId;
  final String status;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  FigurePanelRow({
    required this.id,
    required this.figureId,
    required this.panelLabel,
    required this.title,
    required this.caption,
    required this.sourceNoteId,
    required this.sourceAttachmentId,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
}

class NoteAttachmentRow {
  final int id;
  final int noteId;
  final String filePath;
  final String? mimeType;
  final String kind;
  final DateTime createdAt;

  NoteAttachmentRow({
    required this.id,
    required this.noteId,
    required this.filePath,
    required this.mimeType,
    required this.kind,
    required this.createdAt,
  });
}

// =====================================================
// Drift Tables
// =====================================================

class DbNotes extends Table {
  IntColumn get id => integer().autoIncrement()();

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

class DbFigures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get project => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  TextColumn get layoutType =>
      text().withDefault(const Constant('grid_2x2'))();

  TextColumn get caption => text().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DbFigurePanels extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get figureId =>
      integer().references(DbFigures, #id, onDelete: KeyAction.cascade)();

  TextColumn get panelLabel => text()();
  TextColumn get title => text().nullable()();
  TextColumn get caption => text().nullable()();

  IntColumn get sourceNoteId => integer().nullable()();
  IntColumn get sourceAttachmentId => integer().nullable()();

  TextColumn get status => text().withDefault(const Constant('draft'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DbNoteAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get noteId =>
      integer().references(DbNotes, #id, onDelete: KeyAction.cascade)();

  TextColumn get filePath => text()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get kind => text().withDefault(const Constant('image'))();

  DateTimeColumn get createdAt => dateTime()();
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
    DbFigures,
    DbFigurePanels,
    DbNoteAttachments,
  ],
  daos: [NoteItemsDao],
)
class AppDatabase extends _$AppDatabase implements NotesRepository {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  late final NoteItemsDao noteItemsDao = NoteItemsDao(this);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 5) {
            await m.createTable(dbFigures);
            await m.createTable(dbFigurePanels);
          }

          if (from < 6) {
            await m.addColumn(dbFigures, dbFigures.layoutType);
            await m.addColumn(dbFigures, dbFigures.caption);
          }

          if (from < 7) {
            await m.createTable(dbNoteAttachments);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await _createIndexes();
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

  Future<int> insertNoteAttachment({
    required int noteId,
    required String filePath,
    String? mimeType,
    String kind = 'image',
  }) {
    return into(dbNoteAttachments).insert(
      DbNoteAttachmentsCompanion.insert(
        noteId: noteId,
        filePath: filePath,
        createdAt: DateTime.now(),
        mimeType: Value(mimeType),
        kind: Value(kind),
      ),
    );
  }

  Future<List<NoteAttachmentRow>> listNoteAttachments(int noteId) async {
    final rows = await (select(dbNoteAttachments)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    return rows
        .map(
          (r) => NoteAttachmentRow(
            id: r.id,
            noteId: r.noteId,
            filePath: r.filePath,
            mimeType: r.mimeType,
            kind: r.kind,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  Future<NoteAttachmentRow?> getNoteAttachmentById(int id) async {
    final row = await (select(dbNoteAttachments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) return null;

    return NoteAttachmentRow(
      id: row.id,
      noteId: row.noteId,
      filePath: row.filePath,
      mimeType: row.mimeType,
      kind: row.kind,
      createdAt: row.createdAt,
    );
  }

  Future<void> deleteNoteAttachment(int id) {
    return (delete(dbNoteAttachments)..where((t) => t.id.equals(id))).go();
  }

  Future<NoteAttachmentRow?> getPanelAttachment(int panelId) async {
    final panel = await (select(dbFigurePanels)..where((t) => t.id.equals(panelId)))
        .getSingleOrNull();

    final attachmentId = panel?.sourceAttachmentId;
    if (attachmentId == null) return null;

    return getNoteAttachmentById(attachmentId);
  }

  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_db_notes_list_order
      ON db_notes (is_deleted, is_pinned DESC, updated_at DESC, id DESC)
    ''');
  }

  Future<int> insertFigure({
    required String title,
    String? description,
    String? project,
  }) async {
    final now = DateTime.now();

    final maxSortExpr = dbFigures.sortOrder.max();
    final maxSortRow = await (selectOnly(dbFigures)..addColumns([maxSortExpr]))
        .getSingle();

    final maxSort = maxSortRow.read(maxSortExpr) ?? 0;

    return into(dbFigures).insert(
      DbFiguresCompanion.insert(
        title: title,
        createdAt: now,
        updatedAt: now,
        project: Value(project),
        description: Value(description),
        layoutType: const Value('grid_2x2'),
        caption: const Value(null),
        sortOrder: Value(maxSort + 1),
      ),
    );
  }

  Future<List<FigureRow>> listFigures() async {
    await _addFigureColumnsIfNeeded();

    final figures = await (select(dbFigures)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();

    final result = <FigureRow>[];

    for (final f in figures) {
      final panelCountExpr = dbFigurePanels.id.count();
      final countRow = await (selectOnly(dbFigurePanels)
            ..addColumns([panelCountExpr])
            ..where(dbFigurePanels.figureId.equals(f.id)))
          .getSingle();

      final panelCount = countRow.read(panelCountExpr) ?? 0;

      result.add(
        FigureRow(
          id: f.id,
          title: f.title,
          description: f.description,
          project: f.project,
          layoutType: f.layoutType,
          caption: f.caption,
          sortOrder: f.sortOrder,
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          panelCount: panelCount,
        ),
      );
    }

    return result;
  }

  Future<int> insertFigurePanel({
    required int figureId,
    required String panelLabel,
    String? title,
    String? caption,
    int? sourceNoteId,
    int? sourceAttachmentId,
    String status = 'draft',
  }) async {
    final now = DateTime.now();

    final maxSortExpr = dbFigurePanels.sortOrder.max();
    final maxSortRow = await (selectOnly(dbFigurePanels)
          ..addColumns([maxSortExpr])
          ..where(dbFigurePanels.figureId.equals(figureId)))
        .getSingle();

    final maxSort = maxSortRow.read(maxSortExpr) ?? 0;

    final id = await into(dbFigurePanels).insert(
      DbFigurePanelsCompanion.insert(
        figureId: figureId,
        panelLabel: panelLabel,
        createdAt: now,
        updatedAt: now,
        title: Value(title),
        caption: Value(caption),
        sourceNoteId: Value(sourceNoteId),
        sourceAttachmentId: Value(sourceAttachmentId),
        status: Value(status),
        sortOrder: Value(maxSort + 1),
      ),
    );

    await (update(dbFigures)..where((t) => t.id.equals(figureId))).write(
      DbFiguresCompanion(
        updatedAt: Value(now),
      ),
    );

    return id;
  }

  Future<List<FigurePanelRow>> listFigurePanels(int figureId) async {
    final rows = await (select(dbFigurePanels)
          ..where((t) => t.figureId.equals(figureId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();

    return rows
        .map(
          (r) => FigurePanelRow(
            id: r.id,
            figureId: r.figureId,
            panelLabel: r.panelLabel,
            title: r.title,
            caption: r.caption,
            sourceNoteId: r.sourceNoteId,
            sourceAttachmentId: r.sourceAttachmentId,
            status: r.status,
            sortOrder: r.sortOrder,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<void> updateFigure({
    required int id,
    required String title,
    String? description,
    String? project,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        title: Value(title),
        description: Value(description),
        project: Value(project),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateFigurePanel({
    required int id,
    required String panelLabel,
    String? title,
    String? caption,
    String status = 'draft',
  }) {
    return (update(dbFigurePanels)..where((t) => t.id.equals(id))).write(
      DbFigurePanelsCompanion(
        panelLabel: Value(panelLabel),
        title: Value(title),
        caption: Value(caption),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteFigure(int id) {
    return (delete(dbFigures)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteFigurePanel(int id) {
    return (delete(dbFigurePanels)..where((t) => t.id.equals(id))).go();
  }

  Future<FigureRow?> getFigureById(int id) async {
    final f =
        await (select(dbFigures)..where((t) => t.id.equals(id))).getSingleOrNull();

    if (f == null) return null;

    final panelCountExpr = dbFigurePanels.id.count();
    final countRow = await (selectOnly(dbFigurePanels)
          ..addColumns([panelCountExpr])
          ..where(dbFigurePanels.figureId.equals(f.id)))
        .getSingle();

    final panelCount = countRow.read(panelCountExpr) ?? 0;

    return FigureRow(
      id: f.id,
      title: f.title,
      description: f.description,
      project: f.project,
      layoutType: f.layoutType,
      caption: f.caption,
      sortOrder: f.sortOrder,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
      panelCount: panelCount,
    );
  }

  Future<void> updateFigureLayout({
    required int id,
    required String layoutType,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        layoutType: Value(layoutType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateFigureCaption({
    required int id,
    String? caption,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        caption: Value(caption),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> reorderFigurePanels({
    required int figureId,
    required List<int> panelIdsInOrder,
  }) async {
    await transaction(() async {
      for (var i = 0; i < panelIdsInOrder.length; i++) {
        await (update(dbFigurePanels)
              ..where((t) => t.id.equals(panelIdsInOrder[i])))
            .write(
          DbFigurePanelsCompanion(
            sortOrder: Value(i + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await (update(dbFigures)..where((t) => t.id.equals(figureId))).write(
        DbFiguresCompanion(
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<String> getNextPanelLabel(int figureId) async {
    final panels = await listFigurePanels(figureId);

    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    for (final ch in letters.split('')) {
      final exists = panels.any(
        (p) => p.panelLabel.trim().toUpperCase() == ch,
      );
      if (!exists) return ch;
    }

    return 'P${panels.length + 1}';
  }

  Future<void> _addFigureColumnsIfNeeded() async {
    if (await _hasTable('db_figures')) {
      if (!await _hasColumn('db_figures', 'layout_type')) {
        await customStatement(
          "ALTER TABLE db_figures ADD COLUMN layout_type TEXT NOT NULL DEFAULT 'grid_2x2';",
        );
      }
      if (!await _hasColumn('db_figures', 'caption')) {
        await customStatement(
          'ALTER TABLE db_figures ADD COLUMN caption TEXT;',
        );
      }
    }
  }

  // =====================================================
  // Cursor helpers
  // =====================================================

  Expression<bool> _buildSearchFilter($DbNotesTable tbl, String query) {
    final q = query.trim();
    if (q.isEmpty) {
      return const Constant(true);
    }

    final pattern = '%$q%';
    return tbl.title.like(pattern) |
        tbl.body.like(pattern) |
        tbl.project.like(pattern);
  }

  Expression<bool> _buildCursorFilter(
    $DbNotesTable tbl, {
    required DateTime lastUpdatedAt,
    required int lastId,
    required bool lastIsPinned,
  }) {
    final samePinned = tbl.isPinned.equals(lastIsPinned);

    final movedFromPinnedTrueToFalse =
        lastIsPinned ? tbl.isPinned.equals(false) : const Constant(false);

    final olderUpdatedInSamePinned =
        samePinned & tbl.updatedAt.isSmallerThanValue(lastUpdatedAt);

    final olderIdInSamePinnedAndSameUpdated =
        samePinned &
        tbl.updatedAt.equals(lastUpdatedAt) &
        tbl.id.isSmallerThanValue(lastId);

    return movedFromPinnedTrueToFalse |
        olderUpdatedInSamePinned |
        olderIdInSamePinnedAndSameUpdated;
  }

  String _escapeLike(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  NoteListRow _mapNoteListRow(QueryRow row) {
    return NoteListRow(
      id: row.read<int>('id'),
      title: row.read<String>('title'),
      preview: row.read<String>('preview'),
      createdAt: row.read<DateTime>('created_at'),
      updatedAt: row.read<DateTime>('updated_at'),
      isPinned: row.read<bool>('is_pinned'),
      isLocked: row.read<bool>('is_locked'),
      project: row.readNullable<String>('project'),
    );
  }

  // =====================================================
  // Cursor pagination
  // =====================================================

  @override
  Future<List<Note>> listNotesFirstPage({
    required String query,
    required int limit,
  }) async {
    final stmt = select(dbNotes)
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => _buildSearchFilter(t, query))
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<Note>> listNotesAfterCursor({
    required String query,
    required int limit,
    required DateTime lastUpdatedAt,
    required int lastId,
    required bool lastIsPinned,
  }) async {
    final stmt = select(dbNotes)
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => _buildSearchFilter(t, query))
      ..where(
        (t) => _buildCursorFilter(
          t,
          lastUpdatedAt: lastUpdatedAt,
          lastId: lastId,
          lastIsPinned: lastIsPinned,
        ),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  // =====================================================
  // List rows for home list
  // =====================================================

  @override
  Future<List<NoteListRow>> listNoteRowsFirstPage({
    required String query,
    required int limit,
  }) async {
    final q = query.trim();
    final escaped = _escapeLike(q);
    final pattern = '%$escaped%';

    final rows = await customSelect(
      '''
      SELECT
        id,
        title,
        CASE
          WHEN length(trim(replace(body, char(10), ' '))) <= 80
            THEN trim(replace(body, char(10), ' '))
          ELSE substr(trim(replace(body, char(10), ' ')), 1, 80) || '…'
        END AS preview,
        created_at,
        updated_at,
        is_pinned,
        is_locked,
        project
      FROM db_notes
      WHERE is_deleted = 0
        AND (
          ? = ''
          OR title LIKE ? ESCAPE '\\'
          OR body LIKE ? ESCAPE '\\'
          OR project LIKE ? ESCAPE '\\'
        )
      ORDER BY is_pinned DESC, updated_at DESC, id DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(q),
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withInt(limit),
      ],
      readsFrom: {dbNotes},
    ).get();

    return rows.map(_mapNoteListRow).toList(growable: false);
  }

  @override
  Future<List<NoteListRow>> listNoteRowsAfterCursor({
    required String query,
    required int limit,
    required DateTime lastUpdatedAt,
    required int lastId,
    required bool lastIsPinned,
  }) async {
    final q = query.trim();
    final escaped = _escapeLike(q);
    final pattern = '%$escaped%';
    final pinnedInt = lastIsPinned ? 1 : 0;

    final rows = await customSelect(
      '''
      SELECT
        id,
        title,
        CASE
          WHEN length(trim(replace(body, char(10), ' '))) <= 80
            THEN trim(replace(body, char(10), ' '))
          ELSE substr(trim(replace(body, char(10), ' ')), 1, 80) || '…'
        END AS preview,
        created_at,
        updated_at,
        is_pinned,
        is_locked,
        project
      FROM db_notes
      WHERE is_deleted = 0
        AND (
          ? = ''
          OR title LIKE ? ESCAPE '\\'
          OR body LIKE ? ESCAPE '\\'
          OR project LIKE ? ESCAPE '\\'
        )
        AND (
          (is_pinned < ?)
          OR (
            is_pinned = ?
            AND updated_at < ?
          )
          OR (
            is_pinned = ?
            AND updated_at = ?
            AND id < ?
          )
        )
      ORDER BY is_pinned DESC, updated_at DESC, id DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(q),
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withString(pattern),
        Variable.withInt(pinnedInt),
        Variable.withInt(pinnedInt),
        Variable.withDateTime(lastUpdatedAt),
        Variable.withInt(pinnedInt),
        Variable.withDateTime(lastUpdatedAt),
        Variable.withInt(lastId),
        Variable.withInt(limit),
      ],
      readsFrom: {dbNotes},
    ).get();

    return rows.map(_mapNoteListRow).toList(growable: false);
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
      final reagentHasCatalog =
          await _hasColumn('db_note_reagents_old', 'catalog_number');
      final reagentHasLot =
          await _hasColumn('db_note_reagents_old', 'lot_number');
      final reagentHasCompany =
          await _hasColumn('db_note_reagents_old', 'company');
      final reagentHasMemo = await _hasColumn('db_note_reagents_old', 'memo');
      final reagentHasCreatedAt =
          await _hasColumn('db_note_reagents_old', 'created_at');

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
      final materialHasCatalog =
          await _hasColumn('db_note_materials_old', 'catalog_number');
      final materialHasLot =
          await _hasColumn('db_note_materials_old', 'lot_number');
      final materialHasCompany =
          await _hasColumn('db_note_materials_old', 'company');
      final materialHasMemo = await _hasColumn('db_note_materials_old', 'memo');
      final materialHasCreatedAt =
          await _hasColumn('db_note_materials_old', 'created_at');

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
      final refHasMemo = await _hasColumn('db_note_references_old', 'memo');
      final refHasCreatedAt =
          await _hasColumn('db_note_references_old', 'created_at');

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
    if (!await _hasTable('db_figures')) {
      await m.createTable(dbFigures);
    }
    if (!await _hasTable('db_figure_panels')) {
      await m.createTable(dbFigurePanels);
    }
    if (!await _hasTable('db_note_attachments')) {
      await m.createTable(dbNoteAttachments);
    }
  }

  // =====================================================
  // Integrity
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
      stmt.where(
        (t) => t.title.like(like) | t.body.like(like) | t.project.like(like),
      );
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
  Future<void> updateNoteContent(
    int noteId, {
    required String title,
    required String body,
  }) async {
    await updateNote(id: noteId, title: title, body: body);
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
      stmt.where(
        (t) => t.title.like(like) | t.body.like(like) | t.project.like(like),
      );
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
      await delete(dbNoteAttachments).go();
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