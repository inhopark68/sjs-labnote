# Flutter 위젯 버튼 종류와 기능 정리

Flutter에서 “버튼”으로 쓰는 대표 위젯들과 용도(기능)를 한 번에 보기 좋게 정리한 문서입니다.

---

## 1) Material 버튼 (가장 많이 사용)

- **ElevatedButton**
  - 입체감(그림자)이 있는 기본 액션 버튼
  - “저장/확인/로그인” 같은 주요 CTA에 자주 사용

- **FilledButton**
  - 최신 Material 스타일의 채워진 버튼(주요 액션)
  - `ElevatedButton` 대체로 많이 사용 (테마/버전 따라 선택)

- **FilledButton.tonal**
  - 채워졌지만 톤다운된 강조(보조 액션)

- **OutlinedButton**
  - 테두리만 있는 버튼(보조/대안 액션)
  - “취소/나중에” 같은 보조 행동에 적합

- **TextButton**
  - 배경 없이 텍스트만 있는 버튼(가벼운 액션, 링크 느낌)
  - “자세히 보기”, “건너뛰기” 등에 사용

- **IconButton**
  - 아이콘만 있는 버튼(앱바/툴바 액션)
  - `tooltip`을 주면 접근성(Accessibility) 향상

- **FloatingActionButton (FAB)**
  - 화면 위에 떠 있는 원형(또는 확장) 버튼
  - “추가/새로 만들기” 같은 대표 행동에 사용

- **BackButton / CloseButton**
  - 뒤로가기/닫기 전용 아이콘 버튼(네비게이션에 흔함)

---

## 2) 제스처 기반 “버튼처럼” 쓰는 위젯

- **GestureDetector**
  - 탭/더블탭/롱프레스/드래그 등 제스처를 직접 처리
  - 머티리얼 잉크(물결) 효과는 없음

- **InkWell / InkResponse**
  - 탭 시 물결(잉크) 효과 제공 (Material UI에 자연스러움)
  - 카드/리스트 아이템을 “클릭 가능”하게 만들 때 많이 사용

---

## 3) 토글/선택 버튼류 (상태가 있는 버튼)

- **Switch**
  - ON/OFF 토글

- **Checkbox**
  - 체크(다중 선택)

- **Radio**
  - 단일 선택(여러 개 중 1개)

- **ToggleButtons**
  - 여러 토글 버튼을 그룹으로 구성
  - 단일 선택/다중 선택 모두 구현 가능

- **SegmentedButton**
  - 세그먼트 선택 UI(옵션 중 선택)
  - 필터/정렬 같은 선택 UI에 적합

---

## 4) 메뉴/팝업/드롭다운 계열

- **PopupMenuButton**
  - 버튼(예: ⋮)을 눌러 팝업 메뉴를 띄우고 항목 선택

- **DropdownButton / DropdownButtonFormField**
  - 드롭다운 선택(폼 입력에서 자주 사용)

- **MenuAnchor / MenuItemButton**
  - 신규 메뉴 시스템에서 더 유연한 메뉴 구성에 활용
  - (사용 가능 여부는 Flutter/Material 버전에 따라 다를 수 있음)

---

## 5) 버튼 비슷한 “터치 액션” 위젯

- **ListTile (onTap)**
  - 리스트 행 자체가 버튼 역할(설정 화면 등)

- **Card + InkWell**
  - 카드 전체를 눌러 이동/선택하는 UI 구성에 자주 사용

---

## 빠른 선택 가이드

- **가장 중요한 주요 액션(저장/확인)**: `FilledButton` / `ElevatedButton`
- **보조 액션(취소/뒤로)**: `OutlinedButton` / `TextButton`
- **상단 앱바 아이콘 액션**: `IconButton`
- **추가/생성 중심 대표 액션**: `FloatingActionButton`
- **리스트/카드 전체 클릭**: `InkWell` 또는 `ListTile(onTap:)`
