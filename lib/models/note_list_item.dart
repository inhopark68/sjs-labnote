// lib/models/note_list_item.dart (데이터 모델): list_view / main에서 사용할 “노트 한 개의 데이터 구조” 정의

/// 노트 목록 화면에서 사용되는 요약 정보 모델
/// 개별 노트의 리스트 아이템을 표현한다.
class NoteListItem {
  /// 노트의 고유 ID
  final String id;

  /// 노트 제목
  final String title;

  /// 노트 본문의 미리보기 텍스트 (일부 내용만 표시)
  final String bodyPreview;

  /// 노트 생성 일시
  final DateTime createdAt; //주의 포인트 1개: // createdAt이 required이므로, // 더미 데이터를 만들 때 반드시 넣어야 합니다.

  /// 노트 마지막 수정 일시
  final DateTime updatedAt;

  /// 상단 고정 여부 (true이면 리스트 상단에 고정됨)
  final bool isPinned;

  /// 잠금 여부 (true이면 비밀번호/인증 필요)
  final bool isLocked;

  /// 첨부 파일 개수
  final int attachmentCount;

  /// 연결된 시약(Reagent) 개수
  final int reagentCount;

  /// 연결된 세포(Cell) 개수
  final int cellCount;

  /// 연결된 장비(Equipment) 개수
  final int equipmentCount;

  /// 만료된 시약이 포함되어 있는지 여부
  final bool hasExpiredReagent;

  /// 곧 만료될 시약이 포함되어 있는지 여부
  final bool hasExpiringSoon;

  /// 노트에 연결된 태그 이름 목록
  final List<String> tagNames;

  /// [NoteListItem] 생성자
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
}