import 'package:drift/drift.dart';
import '../data/app_database.dart';

part 'note_items_dao.g.dart';

@DriftAccessor(tables: [DbNoteReagents, DbNoteMaterials, DbNoteReferences])
class NoteItemsDao extends DatabaseAccessor<AppDatabase>
    with _$NoteItemsDaoMixin {
  NoteItemsDao(AppDatabase db) : super(db);

  // =========================================================
  // Reagents
  // =========================================================

  Future<List<DbNoteReagent>> listReagents(String noteId) {
    return (select(dbNoteReagents)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteReagent(String id) =>
      (delete(dbNoteReagents)..where((t) => t.id.equals(id))).go();

  /// ✅ UI에서 Value()를 쓰지 않기 위한 Raw Insert
  Future<void> insertReagentRaw({
    required String id,
    required String noteId,
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

  Future<List<DbNoteMaterial>> listMaterials(String noteId) {
    return (select(dbNoteMaterials)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteMaterial(String id) =>
      (delete(dbNoteMaterials)..where((t) => t.id.equals(id))).go();

  /// ✅ UI에서 Value()를 쓰지 않기 위한 Raw Insert
  Future<void> insertMaterialRaw({
    required String id,
    required String noteId,
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

  Future<List<DbNoteReference>> listReferences(String noteId) {
    return (select(dbNoteReferences)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deleteReference(String id) =>
      (delete(dbNoteReferences)..where((t) => t.id.equals(id))).go();

  /// ✅ UI에서 Value()를 쓰지 않기 위한 Raw Insert
  Future<void> insertReferenceRaw({
    required String id,
    required String noteId,
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

  /// ✅ 노트 완전삭제(hard delete) 시: 관련 시약/재료/DOI 모두 삭제
  Future<void> deleteAllForNote(String noteId) async {
    await batch((b) {
      b.deleteWhere(dbNoteReagents, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteMaterials, (t) => t.noteId.equals(noteId));
      b.deleteWhere(dbNoteReferences, (t) => t.noteId.equals(noteId));
    });
  }

  // =========================================================
  // Utils
  // =========================================================

  /// trim 후 비어있으면 null 처리
  String? _clean(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}