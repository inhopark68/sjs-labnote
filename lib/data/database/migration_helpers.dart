part of 'app_database.dart';

extension MigrationHelpers on AppDatabase {
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
}