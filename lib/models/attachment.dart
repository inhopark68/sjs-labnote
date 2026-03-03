class Attachment {
  final String id;
  final String noteId;
  final String type; // 예: 'photo'
  final String path; // 파일 경로 or idb://key
  final String? caption;
  final DateTime createdAt;

  const Attachment({
    required this.id,
    required this.noteId,
    required this.type,
    required this.path,
    this.caption,
    required this.createdAt,
  });
}
