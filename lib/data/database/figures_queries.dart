part of 'app_database.dart';

extension FiguresQueries on AppDatabase {
  Future<int> insertFigure({
    required String title,
    String? description,
    String? project,
  }) async {
    final now = DateTime.now();

    final maxSortExpr = dbFigures.sortOrder.max();
    final maxSortRow = await (selectOnly(dbFigures)..addColumns([maxSortExpr]))
        .getSingle();

    final maxSort = maxSortRow.read(maxSortExpr) ?? 0;

    return into(dbFigures).insert(
      DbFiguresCompanion.insert(
        title: title,
        createdAt: Value(now),
        updatedAt: Value(now),
        project: Value(project),
        description: Value(description),
        layoutType: const Value('grid_2x2'),
        caption: const Value(null),
        sortOrder: Value(maxSort + 1),
      ),
    );
  }

  Future<List<FigureRow>> listFigures() async {
    await _addFigureColumnsIfNeeded();

    final figures = await (select(dbFigures)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .get();

    final result = <FigureRow>[];

    for (final f in figures) {
      final panelCountExpr = dbFigurePanels.id.count();
      final countRow = await (selectOnly(dbFigurePanels)
            ..addColumns([panelCountExpr])
            ..where(dbFigurePanels.figureId.equals(f.id)))
          .getSingle();

      final panelCount = countRow.read(panelCountExpr) ?? 0;

      result.add(
        FigureRow(
          id: f.id,
          title: f.title,
          description: f.description,
          project: f.project,
          layoutType: f.layoutType,
          caption: f.caption,
          sortOrder: f.sortOrder,
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          panelCount: panelCount,
        ),
      );
    }

    return result;
  }

  Future<FigureRow?> getFigureById(int id) async {
    final f =
        await (select(dbFigures)..where((t) => t.id.equals(id))).getSingleOrNull();

    if (f == null) return null;

    final panelCountExpr = dbFigurePanels.id.count();
    final countRow = await (selectOnly(dbFigurePanels)
          ..addColumns([panelCountExpr])
          ..where(dbFigurePanels.figureId.equals(f.id)))
        .getSingle();

    final panelCount = countRow.read(panelCountExpr) ?? 0;

    return FigureRow(
      id: f.id,
      title: f.title,
      description: f.description,
      project: f.project,
      layoutType: f.layoutType,
      caption: f.caption,
      sortOrder: f.sortOrder,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
      panelCount: panelCount,
    );
  }

  Future<void> updateFigure({
    required int id,
    required String title,
    String? description,
    String? project,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        title: Value(title),
        description: Value(description),
        project: Value(project),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteFigure(int id) {
    return (delete(dbFigures)..where((t) => t.id.equals(id))).go();
  }

  Future<List<FigurePanelRow>> listFigurePanels(int figureId) async {
    final rows = await (select(dbFigurePanels)
          ..where((t) => t.figureId.equals(figureId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();

    return rows
        .map(
          (r) => FigurePanelRow(
            id: r.id,
            figureId: r.figureId,
            panelLabel: r.panelLabel,
            title: r.title,
            caption: r.caption,
            sourceNoteId: r.sourceNoteId,
            sourceAttachmentId: r.sourceAttachmentId,
            status: r.status,
            sortOrder: r.sortOrder,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  Future<int> insertFigurePanel({
    required int figureId,
    required String panelLabel,
    String? title,
    String? caption,
    int? sourceNoteId,
    int? sourceAttachmentId,
    String status = 'draft',
  }) async {
    final now = DateTime.now();

    final maxSortExpr = dbFigurePanels.sortOrder.max();
    final maxSortRow = await (selectOnly(dbFigurePanels)
          ..addColumns([maxSortExpr])
          ..where(dbFigurePanels.figureId.equals(figureId)))
        .getSingle();

    final maxSort = maxSortRow.read(maxSortExpr) ?? 0;

    final id = await into(dbFigurePanels).insert(
      DbFigurePanelsCompanion.insert(
        figureId: figureId,
        panelLabel: panelLabel,
        createdAt: Value(now),
        updatedAt: Value(now),
        title: Value(title),
        caption: Value(caption),
        sourceNoteId: Value(sourceNoteId),
        sourceAttachmentId: Value(sourceAttachmentId),
        status: Value(status),
        sortOrder: Value(maxSort + 1),
      ),
    );

    await (update(dbFigures)..where((t) => t.id.equals(figureId))).write(
      DbFiguresCompanion(updatedAt: Value(now)),
    );

    return id;
  }

  Future<void> updateFigurePanel({
    required int id,
    required String panelLabel,
    String? title,
    String? caption,
    String status = 'draft',
  }) {
    return (update(dbFigurePanels)..where((t) => t.id.equals(id))).write(
      DbFigurePanelsCompanion(
        panelLabel: Value(panelLabel),
        title: Value(title),
        caption: Value(caption),
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteFigurePanel(int id) async {
    final panel = await (select(dbFigurePanels)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (panel == null) return;

    await (delete(dbFigurePanels)..where((t) => t.id.equals(id))).go();

    await (update(dbFigures)..where((t) => t.id.equals(panel.figureId))).write(
      DbFiguresCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateFigureLayout({
    required int id,
    required String layoutType,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        layoutType: Value(layoutType),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateFigureCaption({
    required int id,
    String? caption,
  }) {
    return (update(dbFigures)..where((t) => t.id.equals(id))).write(
      DbFiguresCompanion(
        caption: Value(caption),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> reorderFigurePanels({
    required int figureId,
    required List<int> panelIdsInOrder,
  }) async {
    await transaction(() async {
      for (var i = 0; i < panelIdsInOrder.length; i++) {
        await (update(dbFigurePanels)
              ..where((t) => t.id.equals(panelIdsInOrder[i])))
            .write(
          DbFigurePanelsCompanion(
            sortOrder: Value(i + 1),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      await (update(dbFigures)..where((t) => t.id.equals(figureId))).write(
        DbFiguresCompanion(updatedAt: Value(DateTime.now())),
      );
    });
  }

  Future<String> getNextPanelLabel(int figureId) async {
    final rows = await (select(dbFigurePanels)
          ..where((t) => t.figureId.equals(figureId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    const labels = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final exists = rows.any((e) => e.panelLabel.trim().toUpperCase() == label);
      if (!exists) return label;
    }

    return 'P${rows.length + 1}';
  }

  Future<void> _addFigureColumnsIfNeeded() async {
    if (await _hasTable('db_figures')) {
      if (!await _hasColumn('db_figures', 'layout_type')) {
        await customStatement(
          "ALTER TABLE db_figures ADD COLUMN layout_type TEXT NOT NULL DEFAULT 'grid_2x2';",
        );
      }
      if (!await _hasColumn('db_figures', 'caption')) {
        await customStatement(
          'ALTER TABLE db_figures ADD COLUMN caption TEXT;',
        );
      }
    }
  }

  Future<NoteAttachmentRow?> getPanelAttachment(int panelId) async {
    final panel = await (select(dbFigurePanels)..where((t) => t.id.equals(panelId)))
        .getSingleOrNull();

    final attachmentId = panel?.sourceAttachmentId;
    if (attachmentId == null) return null;

    return getNoteAttachmentById(attachmentId);
  }
}