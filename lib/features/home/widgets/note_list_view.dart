import 'package:flutter/material.dart';
import 'package:labnote/features/home/widgets/note_card.dart';
import 'package:labnote/models/note_list_item.dart';

class NoteListView extends StatefulWidget {
  final List<NoteListItem> items;
  final void Function(String noteId) onTap;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;

  // ✅ HomeVm의 상태를 그대로 받아서 “바닥 로딩 행/더 있음”을 정확히 표현
  final bool loadingMore;
  final bool hasMore;

  // ✅ (선택) 빈 상태에서 “새 노트” 버튼을 노출하려면 콜백 받기
  final VoidCallback? onCreate;

  const NoteListView({
    super.key,
    required this.items,
    required this.onTap,
    this.onRefresh,
    this.onLoadMore,
    this.loadingMore = false,
    this.hasMore = true,
    this.onCreate,
  });

  @override
  State<NoteListView> createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> {
  final _controller = ScrollController();
  bool _triggeringLoadMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (widget.onLoadMore == null) return;
    if (!widget.hasMore) return;
    if (widget.loadingMore) return; // ✅ VM이 로딩중이면 중복 트리거 방지
    if (_triggeringLoadMore) return;

    // 끝에서 300px 이내 접근 시 로드
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 300) {
      _triggeringLoadMore = true;
      try {
        await widget.onLoadMore!.call();
      } finally {
        _triggeringLoadMore = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 빈 상태를 더 “메인 화면”스럽게
    if (widget.items.isEmpty) {
      return _EmptyState(onCreate: widget.onCreate);
    }

    // ✅ 바닥 로딩 행을 위한 itemCount 확장
    final extra = (widget.loadingMore || widget.hasMore) ? 1 : 0;

    final list = ListView.builder(
      controller: _controller,
      physics: widget.onRefresh != null
          ? const AlwaysScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemCount: widget.items.length + extra,
      itemBuilder: (_, i) {
        // ✅ 마지막 1칸은 “바닥 상태” 표시
        if (i >= widget.items.length) {
          if (widget.loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (widget.hasMore) {
            // 아직 더 있음(곧 로딩됨) 표시를 가볍게
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('더 불러오는 중…')),
            );
          }
          return const SizedBox(height: 24);
        }

        final it = widget.items[i];
        return NoteCard(
          title: it.title,
          preview: it.bodyPreview,
          updatedAt: it.updatedAt,
          isPinned: it.isPinned,
          isLocked: it.isLocked,
          attachmentCount: it.attachmentCount,
          reagentCount: it.reagentCount,
          cellCount: it.cellCount,
          equipmentCount: it.equipmentCount,
          hasExpiredReagent: it.hasExpiredReagent,
          hasExpiringSoon: it.hasExpiringSoon,
          tagNames: it.tagNames,
          onTap: () => widget.onTap(it.id),
        );
      },
    );

    if (widget.onRefresh == null) return list;

    return RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCreate});
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined, size: 56, color: theme.hintColor),
            const SizedBox(height: 12),
            Text('노트가 없습니다.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '새 노트를 만들어 기록을 시작해보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('새 노트'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
