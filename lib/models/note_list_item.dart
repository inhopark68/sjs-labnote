// lib/models/note_list_item.dart (데이터 모델): list_view / main에서 사용할 “노트 한 개의 데이터 구조” 정의

/// 노트 목록 화면에서 사용되는 요약 정보 모델
/// 개별 노트의 리스트 아이템을 표현한다.
class NoteListItem {
  final int id;
  final String title;
  final String bodyPreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final int attachmentCount;
  final int reagentCount;
  final int cellCount;
  final int equipmentCount;
  final bool hasExpiredReagent;
  final bool hasExpiringSoon;
  final List<String> tagNames;

  NoteListItem({
    required this.id,
    required this.title,
    required this.bodyPreview,
    required this.createdAt,
    required this.updatedAt,
    required this.isPinned,
    required this.isLocked,
    required this.attachmentCount,
    required this.reagentCount,
    required this.cellCount,
    required this.equipmentCount,
    required this.hasExpiredReagent,
    required this.hasExpiringSoon,
    required this.tagNames,
  });

  NoteListItem copyWith({
    String? title,
    String? bodyPreview,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isLocked,
    int? attachmentCount,
    int? reagentCount,
    int? cellCount,
    int? equipmentCount,
    bool? hasExpiredReagent,
    bool? hasExpiringSoon,
    List<String>? tagNames,
  }) {
    return NoteListItem(
      id: id,
      title: title ?? this.title,
      bodyPreview: bodyPreview ?? this.bodyPreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      reagentCount: reagentCount ?? this.reagentCount,
      cellCount: cellCount ?? this.cellCount,
      equipmentCount: equipmentCount ?? this.equipmentCount,
      hasExpiredReagent: hasExpiredReagent ?? this.hasExpiredReagent,
      hasExpiringSoon: hasExpiringSoon ?? this.hasExpiringSoon,
      tagNames: tagNames ?? this.tagNames,
    );
  }
}