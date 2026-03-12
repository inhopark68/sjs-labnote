class FigureListItem {
  final int id;
  final String title;
  final String? description;
  final String? project;
  final String layoutType;
  final String? caption;
  final int panelCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FigureListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.project,
    required this.layoutType,
    required this.caption,
    required this.panelCount,
    required this.createdAt,
    required this.updatedAt,
  });
}