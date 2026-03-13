import 'package:drift/drift.dart';
import '../database/app_database.dart';

part 'note_items_dao.g.dart';

@DriftAccessor(
  tables: [
    DbNoteReagents,
    DbNoteMaterials,
    DbNoteReferences,
  ],
)
class NoteItemsDao extends DatabaseAccessor<AppDatabase>
    with _$NoteItemsDaoMixin {
  NoteItemsDao(super.db);

  Future<List<DbNoteReagent>> listReagents(int noteId) {
    return (select(dbNoteReagents)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<DbNoteMaterial>> listMaterials(int noteId) {
    return (select(dbNoteMaterials)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<DbNoteReference>> listReferences(int noteId) {
    return (select(dbNoteReferences)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteReagent(String id) {
    return (delete(dbNoteReagents)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteMaterial(String id) {
    return (delete(dbNoteMaterials)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteReference(String id) {
    return (delete(dbNoteReferences)..where((t) => t.id.equals(id))).go();
  }

  Future<void> insertReagentRaw({
    required String id,
    required int noteId,
    required String name,
    String? catalogNumber,
    String? lotNumber,
    String? company,
    String? memo,
    DateTime? createdAt,
  }) {
    return into(dbNoteReagents).insert(
      DbNoteReagentsCompanion.insert(
        id: id,
        noteId: noteId,
        name: name,
        catalogNumber: Value(catalogNumber),
        lotNumber: Value(lotNumber),
        company: Value(company),
        memo: Value(memo),
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> insertMaterialRaw({
    required String id,
    required int noteId,
    required String name,
    String? catalogNumber,
    String? lotNumber,
    String? company,
    String? memo,
    DateTime? createdAt,
  }) {
    return into(dbNoteMaterials).insert(
      DbNoteMaterialsCompanion.insert(
        id: id,
        noteId: noteId,
        name: name,
        catalogNumber: Value(catalogNumber),
        lotNumber: Value(lotNumber),
        company: Value(company),
        memo: Value(memo),
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> insertReferenceRaw({
    required String id,
    required int noteId,
    required String doi,
    String? memo,
    DateTime? createdAt,
  }) {
    return into(dbNoteReferences).insert(
      DbNoteReferencesCompanion.insert(
        id: id,
        noteId: noteId,
        doi: doi,
        memo: Value(memo),
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
  }

  Future<void> deleteAllForNote(int noteId) async {
    await batch((b) {
      b.deleteWhere(dbNoteReagents, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteMaterials, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteReferences, (t) => t.noteId.equals(noteId));
    });
  }
}