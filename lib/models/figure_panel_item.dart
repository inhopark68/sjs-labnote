class FigurePanelItem {
  final int id;
  final int figureId;
  final String panelLabel;
  final String? title;
  final String? caption;
  final int? sourceNoteId;
  final int? sourceAttachmentId;
  final String status;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FigurePanelItem({
    required this.id,
    required this.figureId,
    required this.panelLabel,
    required this.title,
    required this.caption,
    required this.sourceNoteId,
    required this.sourceAttachmentId,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
}