// lib/features/home/home_screen.dart 최종본 (HomeVm 연결)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_vm.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();

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
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVm>();

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
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export') {
                await vm.exportBackupPlain(context);
              } else if (v == 'import') {
                await vm.importBackupWithPreRestore(context);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'export', child: Text('백업 내보내기(평문)')),
              PopupMenuItem(value: 'import', child: Text('백업 가져오기(PRE-RESTORE)')),
            ],
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
                      hintText: '검색(제목/미리보기/태그)',
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

                      return ListTile(
                        title: Text(item.title.isEmpty ? '(제목 없음)' : item.title),
                        subtitle: Text(item.bodyPreview),
                        leading: item.isPinned
                            ? const Icon(Icons.push_pin)
                            : const SizedBox.shrink(),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            if (item.hasExpiringSoon || item.hasExpiredReagent)
                              Icon(
                                item.hasExpiredReagent
                                    ? Icons.warning_amber
                                    : Icons.schedule,
                              ),
                            if (item.attachmentCount > 0)
                              Chip(
                                label: Text('📎 ${item.attachmentCount}'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        onTap: () {
                          // TODO: 노트 상세/편집으로 이동 (원하면 라우팅까지 같이 정리해줄게요)
                        },
                      );
                    },
                  ),
                ),
      // 하단 상태 표시(선택)
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