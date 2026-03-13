import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../dao/note_items_dao.dart';

part 'app_database.g.dart';
part 'figures_queries.dart';
part 'notes_queries.dart';
part 'migration_helpers.dart';

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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
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
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class DbNoteAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get noteId =>
      integer().references(DbNotes, #id, onDelete: KeyAction.cascade)();

  TextColumn get filePath => text()();
  TextColumn get mimeType => text().nullable()();
  TextColumn get kind => text().withDefault(const Constant('image'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());
 

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

  Future<void> _createIndexes() async {
    await customStatement('''
      CREATE INDEX IF NOT EXISTS idx_db_notes_list_order
      ON db_notes (is_deleted, is_pinned DESC, updated_at DESC, id DESC)
    ''');
  }
}