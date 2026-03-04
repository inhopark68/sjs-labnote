// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_items_dao.dart';

// ignore_for_file: type=lint
mixin _$NoteItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DbNoteReagentsTable get dbNoteReagents => attachedDatabase.dbNoteReagents;
  $DbNoteMaterialsTable get dbNoteMaterials => attachedDatabase.dbNoteMaterials;
  $DbNoteReferencesTable get dbNoteReferences =>
      attachedDatabase.dbNoteReferences;
  NoteItemsDaoManager get managers => NoteItemsDaoManager(this);
}

class NoteItemsDaoManager {
  final _$NoteItemsDaoMixin _db;
  NoteItemsDaoManager(this._db);
  $$DbNoteReagentsTableTableManager get dbNoteReagents =>
      $$DbNoteReagentsTableTableManager(
        _db.attachedDatabase,
        _db.dbNoteReagents,
      );
  $$DbNoteMaterialsTableTableManager get dbNoteMaterials =>
      $$DbNoteMaterialsTableTableManager(
        _db.attachedDatabase,
        _db.dbNoteMaterials,
      );
  $$DbNoteReferencesTableTableManager get dbNoteReferences =>
      $$DbNoteReferencesTableTableManager(
        _db.attachedDatabase,
        _db.dbNoteReferences,
      );
}
