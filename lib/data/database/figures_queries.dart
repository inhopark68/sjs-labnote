part of 'app_database.dart';

extension FiguresQueries on AppDatabase {

  Future<List<FigureRow>> listFigures() async {
    final figures = await (select(dbFigures)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();

    final result = <FigureRow>[];

    for (final f in figures) {
      final countExp = dbFigurePanels.id.count();

      final row = await (selectOnly(dbFigurePanels)
            ..addColumns([countExp])
            ..where(dbFigurePanels.figureId.equals(f.id)))
          .getSingle();

      final count = row.read(countExp) ?? 0;

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
          panelCount: count,
        ),
      );
    }

    return result;
  }

  Future<void> deleteFigure(int id) {
    return (delete(dbFigures)..where((t) => t.id.equals(id))).go();
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
}