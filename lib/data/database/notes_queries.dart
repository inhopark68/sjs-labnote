part of 'app_database.dart';

extension NotesQueries on AppDatabase {
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
        createdAt: Value(DateTime.now()),
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

  Expression<bool> _buildSearchFilter($DbNotesTable tbl, String query) {
    final q = query.trim();
    if (q.isEmpty) return const Constant(true);

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

  Future<void> deleteNote(int id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> restoreNote(int id) async {
    await (update(dbNotes)..where((t) => t.id.equals(id))).write(
      DbNotesCompanion(
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

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

  Future<void> hardDeleteNote(int id) async {
    await transaction(() async {
      await noteItemsDao.deleteAllForNote(id);
      await (delete(dbNotes)..where((t) => t.id.equals(id))).go();
    });
  }

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

  Future<List<DbNote>> allNoteRowsIncludingDeleted() {
    final stmt = select(dbNotes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
    return stmt.get();
  }
}