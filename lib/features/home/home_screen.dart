import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/features/notes/note_detail_page.dart';

import 'home_vm.dart';
import '../trash/trash_screen.dart'; // 경로 맞게

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  bool _inited = false;

  @override
  void initState() {
    super.initState();

    // 스크롤 끝에 가까워지면 loadMore()
    _scrollCtrl.addListener(() {
      final vm = context.read<HomeVm>();
      if (_scrollCtrl.position.pixels >
          _scrollCtrl.position.maxScrollExtent - 200) {
        vm.loadMore();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    // 홈 진입 시 1회 초기화
    Future.microtask(() => context.read<HomeVm>().init());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVm>();
    final db = context.read<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LabNote'),
        actions: [
          IconButton(
            tooltip: vm.searchVisible ? '검색 닫기' : '검색',
            icon: Icon(vm.searchVisible ? Icons.close : Icons.search),
            onPressed: vm.toggleSearch,
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: vm.loading ? null : vm.refresh,
          ),

          IconButton(
            tooltip: '휴지통',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );
              // 휴지통에서 복원/삭제 후 돌아오면 목록 갱신
              context.read<HomeVm>().init(); // 또는 loadMore 구조에 맞춰 갱신 메서드 호출
            },
          ),
        ],
        bottom: vm.searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '검색(제목/본문)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: vm.setQuery,
                  ),
                ),
              )
            : null,
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.items.isEmpty
              ? const Center(child: Text('표시할 노트가 없습니다.'))
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.separated(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: vm.items.length + (vm.loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // 로딩 더보기 표시
                      if (index >= vm.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = vm.items[index];

                      // ✅ 스와이프 삭제 + Undo
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('삭제할까요?'),
                              content: const Text('노트가 삭제됨으로 표시됩니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          return ok == true;
                        },
                        onDismissed: (_) async {
                          await db.deleteNote(item.id);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('삭제됨'),
                              action: SnackBarAction(
                                label: '되돌리기',
                                onPressed: () async {
                                  await db.restoreNote(item.id);
                                  if (context.mounted) {
                                    await vm.refresh();
                                  }
                                },
                              ),
                            ),
                          );

                          await vm.refresh();
                        },
                        child: ListTile(
                          title:
                              Text(item.title.isEmpty ? '(제목 없음)' : item.title),
                          subtitle: Text(item.bodyPreview),
                          leading: item.isPinned
                              ? const Icon(Icons.push_pin)
                              : const SizedBox.shrink(),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NoteDetailPage(noteId: item.id),
                              ),
                            );
                            if (changed == true) {
                              await vm.refresh();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: '새 노트',
        child: const Icon(Icons.add),
        onPressed: () async {
          final id = await vm.insertEmptyAndReturnId();
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => NoteDetailPage(noteId: id)),
          );

          // 돌아오면 목록 갱신
          if (changed == true) {
            await vm.refresh();
          } else {
            await vm.refresh();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: (vm.hasMore && !vm.loading && vm.items.isNotEmpty)
          ? const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '스크롤하면 더 불러옵니다',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
    );
  }
}