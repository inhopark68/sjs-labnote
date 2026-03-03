import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:labnote/features/home/home_vm.dart';
import 'package:labnote/features/home/widgets/note_list_view.dart';
import 'package:labnote/features/note_sheet/note_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final Uri _homepage = Uri.parse('https://example.com');

  Future<void> _openHomepage(BuildContext context) async {
    try {
      final ok = await launchUrl(
        _homepage,
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('브라우저를 열 수 없어요.')));
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('브라우저를 열 수 없어요. URL을 확인해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVm>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: '홈페이지 열기',
            onPressed: () => _openHomepage(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: vm.searchVisible ? '검색 닫기' : '검색',
            onPressed: vm.toggleSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'backup') {
                await vm.exportBackupPlain(context);
              } else if (v == 'restore') {
                await vm.importBackupWithPreRestore(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'backup', child: Text('백업 내보내기(평문)')),
              PopupMenuItem(
                value: 'restore',
                child: Text('복원 (PRE-RESTORE 포함)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (vm.loading || vm.loadingMore)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          if (vm.searchVisible)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '검색',
                  border: OutlineInputBorder(),
                ),
                onChanged: vm.setQuery,
              ),
            ),
          Expanded(
            child: NoteListView(
              items: vm.items,
              onTap: (id) => _openNoteSheet(context, noteId: id),
              onRefresh: vm.refresh,
              onLoadMore: vm.hasMore ? vm.loadMore : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openNoteSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('새 노트'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNoteSheet(BuildContext context, {String? noteId}) async {
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => NoteSheet(noteId: noteId),
    );
  }
}
