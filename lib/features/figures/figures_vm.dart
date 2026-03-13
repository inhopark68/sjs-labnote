import 'package:flutter/foundation.dart';

import 'package:labnote/data/database/app_database.dart';
import 'package:labnote/models/figure_list_item.dart';
import 'package:labnote/models/figure_panel_item.dart';

class FiguresVm extends ChangeNotifier {
  FiguresVm(this._db);

  final AppDatabase _db;

  bool loading = false;
  final List<FigureListItem> figures = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      final rows = await _db.listFigures();

      figures
        ..clear()
        ..addAll(
          rows.map(
            (r) => FigureListItem(
              id: r.id,
              title: r.title,
              description: r.description,
              project: r.project,
              layoutType: r.layoutType,
              caption: r.caption,
              panelCount: r.panelCount,
              createdAt: r.createdAt,
              updatedAt: r.updatedAt,
            ),
          ),
        );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> createFigure({
    required String title,
    String? description,
    String? project,
  }) async {
    await _db.insertFigure(
      title: title,
      description: description,
      project: project,
    );
    await load();
  }

  Future<void> updateFigure({
    required int id,
    required String title,
    String? description,
    String? project,
  }) async {
    await _db.updateFigure(
      id: id,
      title: title,
      description: description,
      project: project,
    );
    await load();
  }

  Future<void> deleteFigure(int id) async {
    await _db.deleteFigure(id);
    await load();
  }
}

class FigureDetailVm extends ChangeNotifier {
  FigureDetailVm(this._db, this.figureId);

  final AppDatabase _db;
  final int figureId;

  bool loading = false;
  FigureListItem? figure;
  final List<FigurePanelItem> panels = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      final figureRow = await _db.getFigureById(figureId);
      final panelRows = await _db.listFigurePanels(figureId);

      figure = figureRow == null
          ? null
          : FigureListItem(
              id: figureRow.id,
              title: figureRow.title,
              description: figureRow.description,
              project: figureRow.project,
              layoutType: figureRow.layoutType,
              caption: figureRow.caption,
              panelCount: figureRow.panelCount,
              createdAt: figureRow.createdAt,
              updatedAt: figureRow.updatedAt,
            );

      panels
        ..clear()
        ..addAll(
          panelRows.map(
            (r) => FigurePanelItem(
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
          ),
        );
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> createPanel({
    required String panelLabel,
    String? title,
    String? caption,
    int? sourceNoteId,
    int? sourceAttachmentId,
  }) async {
    await _db.insertFigurePanel(
      figureId: figureId,
      panelLabel: panelLabel,
      title: title,
      caption: caption,
      sourceNoteId: sourceNoteId,
      sourceAttachmentId: sourceAttachmentId,
    );
    await load();
  }

Future<void> updatePanel({
    required int id,
    required String panelLabel,
    String? title,
    String? caption,
    required String status,
    int? sourceNoteId,
    int? sourceAttachmentId,
  }) async {
    await _db.updateFigurePanel(
      id: id,
      panelLabel: panelLabel,
      title: title,
      caption: caption,
      status: status,
      sourceNoteId: sourceNoteId,
      sourceAttachmentId: sourceAttachmentId,
    );
    await load();
    notifyListeners();
  }

  Future<void> deletePanel(int id) async {
    await _db.deleteFigurePanel(id);
    await load();
  }

  Future<void> updateLayout(String layoutType) async {
    await _db.updateFigureLayout(
      id: figureId,
      layoutType: layoutType,
    );
    await load();
  }

  Future<void> updateCaption(String? caption) async {
    await _db.updateFigureCaption(
      id: figureId,
      caption: caption,
    );
    await load();
  }

  Future<void> reorderPanels(List<int> panelIdsInOrder) async {
    await _db.reorderFigurePanels(
      figureId: figureId,
      panelIdsInOrder: panelIdsInOrder,
    );
    await load();
  }

  Future<String> getNextPanelLabel() {
    return _db.getNextPanelLabel(figureId);
  }
}