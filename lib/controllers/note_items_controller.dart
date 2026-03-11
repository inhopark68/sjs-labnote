import 'package:flutter/material.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/widgets/doi_entry_dialog.dart';
import 'package:labnote/widgets/note_item_dialog.dart';

class NoteItemsController {
  final AppDatabase db;
  final int noteId;
  final String Function() newIdBuilder;

  List<DbNoteReagent> reagents = const [];
  List<DbNoteMaterial> materials = const [];
  List<DbNoteReference> references = const [];

  NoteItemsController({
    required this.db,
    required this.noteId,
    required this.newIdBuilder,
  });

  Future<void> loadAll() async {
    reagents = await db.noteItemsDao.listReagents(noteId);
    materials = await db.noteItemsDao.listMaterials(noteId);
    references = await db.noteItemsDao.listReferences(noteId);
  }

  Future<bool> addReagent({
    required BuildContext context,
    required bool enableOcr,
    required Future<String?> Function()? onRequestOcrText,
  }) async {
    final input = await showDialog<ItemEntryInput?>(
      context: context,
      builder: (_) => ItemEntryDialog(
        title: '시약 추가',
        enableOcr: enableOcr,
        onRequestOcrText: onRequestOcrText,
      ),
    );

    if (input == null) return false;

    await db.noteItemsDao.insertReagentRaw(
      id: newIdBuilder(),
      noteId: noteId,
      name: input.name,
      catalogNumber: input.catalogNumber,
      lotNumber: input.lotNumber,
      company: input.company,
      memo: input.memo,
      createdAt: DateTime.now(),
    );

    await loadAll();
    return true;
  }

  Future<bool> addMaterial({
    required BuildContext context,
    required bool enableOcr,
    required Future<String?> Function()? onRequestOcrText,
  }) async {
    final input = await showDialog<ItemEntryInput?>(
      context: context,
      builder: (_) => ItemEntryDialog(
        title: '재료 추가',
        enableOcr: enableOcr,
        onRequestOcrText: onRequestOcrText,
      ),
    );

    if (input == null) return false;

    await db.noteItemsDao.insertMaterialRaw(
      id: newIdBuilder(),
      noteId: noteId,
      name: input.name,
      catalogNumber: input.catalogNumber,
      lotNumber: input.lotNumber,
      company: input.company,
      memo: input.memo,
      createdAt: DateTime.now(),
    );

    await loadAll();
    return true;
  }

  Future<bool> addReference({
    required BuildContext context,
    required bool enableOcr,
    required Future<String?> Function()? onRequestOcrText,
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => DoiEntryDialog(
        enableOcr: enableOcr,
        onRequestOcrText: onRequestOcrText,
      ),
    );

    if (result == null) return false;

    if (result is DoiEntryInput) {
      await db.noteItemsDao.insertReferenceRaw(
        id: newIdBuilder(),
        noteId: noteId,
        doi: result.doi,
        memo: result.memo,
        createdAt: DateTime.now(),
      );
      await loadAll();
      return true;
    }

    if (result is List<DoiEntryInput>) {
      for (final input in result) {
        await db.noteItemsDao.insertReferenceRaw(
          id: newIdBuilder(),
          noteId: noteId,
          doi: input.doi,
          memo: input.memo,
          createdAt: DateTime.now(),
        );
      }
      await loadAll();
      return true;
    }

    return false;
  }

  Future<void> deleteReagent(String id) async {
    await db.noteItemsDao.deleteReagent(id);
    await loadAll();
  }

  Future<void> deleteMaterial(String id) async {
    await db.noteItemsDao.deleteMaterial(id);
    await loadAll();
  }

  Future<void> deleteReference(String id) async {
    await db.noteItemsDao.deleteReference(id);
    await loadAll();
  }
}