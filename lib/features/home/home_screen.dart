import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/features/notes/note_detail_page.dart';


import 'package:labnote/features/home/home_vm.dart';
import 'package:labnote/features/trash/trash_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  bool _inited = false;

  HomeVm? _vm; // ✅ 스크롤 리스너에서 context.read 반복 방지

  @override
  void initState() {
    super.initState();

    // ✅ initState에서 context.read/watch는 피하고, 첫 프레임 이후에 세팅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _vm = context.read<HomeVm>();

      _scrollCtrl.addListener(() {
        final vm = _vm;
        if (vm == null) return;

        if (_scrollCtrl.position.pixels >
            _scrollCtrl.position.maxScrollExtent - 200) {
          vm.loadMore();
        }
      });
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
              if (!context.mounted) return;
              await context.read<HomeVm>().refresh();
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
                      if (index >= vm.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = vm.items[index];

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
                          title: Text(item.title.isEmpty ? '(제목 없음)' : item.title),
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
          try {
            final id = await vm.insertEmptyAndReturnId();
            debugPrint('new note id=$id (${id.runtimeType})');

            if (!context.mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailPage(noteId: id)),
            );

            if (!mounted) return;
            await vm.refresh();
          } catch (e, st) {
            debugPrint('new note failed: $e\n$st');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('새 노트 열기 실패: $e')),
            );
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