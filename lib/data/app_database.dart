import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'app_database.g.dart';

/// 앱 내부에서 쓰는 저장소 인터페이스 (VM/서비스가 DB 구현에 덜 의존하게)
abstract class NotesRepository {
  Future<List<Note>> listNotes({
    String query = '',
    int? limit,
    int? offset,
  });

  Future<Note?> getNote(String id);

  Future<String> insertNote({required String title, required String body});
  Future<void> updateNote({
    required String id,
    required String title,
    required String body,
  });

  Future<void> deleteNote(String id); // soft delete
  Future<void> togglePin(String id);

  Future<void> replaceAllNotesFromBackup(List<Note> notes);
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
      web: kIsWeb
          ? DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
            )
          : null,
    );
  }

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

    // ✅ pinned 먼저, updatedAt 최신 먼저 + 정렬 안정성 타이브레이커(id)
    stmt.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
    ]);

    // ✅ DB pagination
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
  Future<String> insertNote({required String title, required String body}) async {
    final now = DateTime.now();
    final id = _newId();

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

  /// soft delete
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

  /// 백업/복원에서 쓰는: 삭제 포함 전체 Row 읽기
  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    return select(dbNotes).get();
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
      );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
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
}