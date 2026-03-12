import 'package:drift/drift.dart';

import '../app_database.dart';

part 'note_items_dao.g.dart';

@DriftAccessor(
  tables: [DbNoteReagents, DbNoteMaterials, DbNoteReferences],
)
class NoteItemsDao extends DatabaseAccessor<AppDatabase>
    with _$NoteItemsDaoMixin {
  NoteItemsDao(AppDatabase db) : super(db);

  // =========================================================
  // Reagents
  // =========================================================

  Future<List<DbNoteReagent>> listReagents(int noteId) {
    return (select(dbNoteReagents)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteReagent(String id) {
    return (delete(dbNoteReagents)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertReagentRaw({
    required String id,
    required int noteId,
    required String name,
    String? catalogNumber,
    String? lotNumber,
    String? company,
    String? memo,
    required DateTime createdAt,
  }) {
    return into(dbNoteReagents).insert(
      DbNoteReagentsCompanion.insert(
        id: id,
        noteId: noteId,
        name: name,
        createdAt: createdAt,
        catalogNumber: Value(_clean(catalogNumber)),
        lotNumber: Value(_clean(lotNumber)),
        company: Value(_clean(company)),
        memo: Value(_clean(memo)),
      ),
    );
  }

  // =========================================================
  // Materials
  // =========================================================

  Future<List<DbNoteMaterial>> listMaterials(int noteId) {
    return (select(dbNoteMaterials)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteMaterial(String id) {
    return (delete(dbNoteMaterials)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertMaterialRaw({
    required String id,
    required int noteId,
    required String name,
    String? catalogNumber,
    String? lotNumber,
    String? company,
    String? memo,
    required DateTime createdAt,
  }) {
    return into(dbNoteMaterials).insert(
      DbNoteMaterialsCompanion.insert(
        id: id,
        noteId: noteId,
        name: name,
        createdAt: createdAt,
        catalogNumber: Value(_clean(catalogNumber)),
        lotNumber: Value(_clean(lotNumber)),
        company: Value(_clean(company)),
        memo: Value(_clean(memo)),
      ),
    );
  }

  // =========================================================
  // References (DOI)
  // =========================================================

  Future<List<DbNoteReference>> listReferences(int noteId) {
    return (select(dbNoteReferences)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteReference(String id) {
    return (delete(dbNoteReferences)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertReferenceRaw({
    required String id,
    required int noteId,
    required String doi,
    String? memo,
    required DateTime createdAt,
  }) {
    return into(dbNoteReferences).insert(
      DbNoteReferencesCompanion.insert(
        id: id,
        noteId: noteId,
        doi: doi,
        createdAt: createdAt,
        memo: Value(_clean(memo)),
      ),
    );
  }

  // =========================================================
  // Integrity helpers
  // =========================================================

  Future<void> deleteAllForNote(int noteId) async {
    await batch((b) {
      b.deleteWhere(dbNoteReagents, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteMaterials, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteReferences, (t) => t.noteId.equals(noteId));
    });
  }

  // =========================================================
  // Utils
  // =========================================================

  String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}