import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
<<<<<<< HEAD
import 'package:flutter/foundation.dart' show kIsWeb;
=======
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3

part 'app_database.g.dart';

abstract class NotesRepository {
  Future<List<Note>> listNotes({String query = ''});
  Future<Note?> getNote(String id);

  Future<String> insertNote({required String title, required String body});
  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
  });

<<<<<<< HEAD
  Future<void> deleteNote(String id); // soft delete
  Future<void> togglePin(String id);
=======
  Future<void> deleteNote(String id);
  Future<void> togglePin(String id);

  Future<void> replaceAllNotesFromBackup(List<Note> notes);
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
}

class DbNotes extends Table {
  TextColumn get id => text()();

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

@DriftDatabase(tables: [DbNotes])
class AppDatabase extends _$AppDatabase implements NotesRepository {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'labnote',
<<<<<<< HEAD
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'), // ✅ 여기!
            )
          : null,
    );
  }
  @override
  Future<List<Note>> listNotes({String query = ''}) async {
    final q = query.trim();

=======
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  @override
  Future<List<Note>> listNotes({String query = ''}) async {
    final q = query.trim();
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
    final stmt = select(dbNotes)..where((t) => t.isDeleted.equals(false));

    if (q.isNotEmpty) {
      final like = '%$q%';
      stmt.where((t) => t.title.like(like) | t.body.like(like));
    }

    stmt.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    final rows = await stmt.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<Note?> getNote(String id) async {
<<<<<<< HEAD
    final row = await (select(dbNotes)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .getSingleOrNull();
=======
    final row =
        await (select(dbNotes)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();

>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
    return row == null ? null : _toDomain(row);
  }

  @override
<<<<<<< HEAD
  Future<String> insertNote({required String title, required String body}) async {
    final now = DateTime.now();
    final id = _newId();
=======
  Future<String> insertNote({
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3

    await into(dbNotes).insert(
      DbNotesCompanion.insert(
        id: id,
        title: Value(title),
        body: Value(body),
        createdAt: now,
        updatedAt: now,
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
  Future<void> togglePin(String id) async {
<<<<<<< HEAD
    final current =
        await (select(dbNotes)..where((t) => t.id.equals(id))).getSingleOrNull();
=======
    final current = await (select(
      dbNotes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
    if (current == null || current.isDeleted) return;

    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isPinned: Value(!current.isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

<<<<<<< HEAD
  // ✅ 백업/복원에서 쓸 "전체 읽기/전체 덮어쓰기" 유틸
  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    return select(dbNotes).get();
  }

=======
  @override
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  Future<void> replaceAllNotesFromBackup(List<Note> notes) async {
    await transaction(() async {
      await delete(dbNotes).go();

      await batch((b) {
        b.insertAll(
          dbNotes,
          notes.map((n) {
            return DbNotesCompanion.insert(
              id: n.id,
              title: Value(n.title),
              body: Value(n.body),
              createdAt: n.createdAt,
              updatedAt: n.updatedAt,
              isPinned: Value(n.isPinned),
              isLocked: Value(n.isLocked),
              isDeleted: Value(n.isDeleted),
              project: Value(n.project),
            );
          }).toList(),
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Note _toDomain(DbNote r) => Note(
<<<<<<< HEAD
        id: r.id,
        title: r.title,
        body: r.body,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        isPinned: r.isPinned,
        isLocked: r.isLocked,
        isDeleted: r.isDeleted,
        project: r.project,
      );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
=======
    id: r.id,
    title: r.title,
    body: r.body,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
    isPinned: r.isPinned,
    isLocked: r.isLocked,
    isDeleted: r.isDeleted,
    project: r.project,
  );
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
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
  });
<<<<<<< HEAD
}
=======
}
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
