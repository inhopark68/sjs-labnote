import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/features/figures/figure_detail_screen.dart';
import 'package:labnote/features/figures/figures_vm.dart';

class FiguresScreen extends StatelessWidget {
  const FiguresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FiguresVm(ctx.read<AppDatabase>())..load(),
      child: const _FiguresScreenBody(),
    );
  }
}

class _FiguresScreenBody extends StatelessWidget {
  const _FiguresScreenBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FiguresVm>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Figures'),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (context) {
            if (vm.loading && vm.figures.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (vm.figures.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('등록된 Figure가 없습니다.')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: vm.figures.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = vm.figures[index];

                return ListTile(
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.project?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.project!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        item.description?.trim().isNotEmpty == true
                            ? item.description!
                            : '패널 ${item.panelCount}개',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FigureDetailScreen(
                          figureId: item.id,
                          title: item.title,
                        ),
                      ),
                    );

                    if (!context.mounted) return;
                    await context.read<FiguresVm>().refresh();
                  },
                  onLongPress: () => _showFigureActions(context, item.id, item.title),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '새 Figure',
        onPressed: () => _showCreateFigureDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateFigureDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final projectCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 Figure'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: 'Figure 1',
                ),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: '설명',
                ),
                maxLines: 2,
              ),
              TextField(
                controller: projectCtrl,
                decoration: const InputDecoration(
                  labelText: '프로젝트',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    await context.read<FiguresVm>().createFigure(
          title: title,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          project: projectCtrl.text.trim().isEmpty ? null : projectCtrl.text.trim(),
        );
  }

  Future<void> _showEditFigureDialog(
    BuildContext context, {
    required int id,
    required String initialTitle,
    String? initialDescription,
    String? initialProject,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle);
    final descCtrl = TextEditingController(text: initialDescription ?? '');
    final projectCtrl = TextEditingController(text: initialProject ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Figure 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 2,
              ),
              TextField(
                controller: projectCtrl,
                decoration: const InputDecoration(labelText: '프로젝트'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;

    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;

    await context.read<FiguresVm>().updateFigure(
          id: id,
          title: title,
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
          project: projectCtrl.text.trim().isEmpty ? null : projectCtrl.text.trim(),
        );
  }

  Future<void> _showFigureActions(
    BuildContext context,
    int id,
    String title,
  ) async {
    final vm = context.read<FiguresVm>();
    final figure = vm.figures.firstWhere((e) => e.id == id);

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      await _showEditFigureDialog(
        context,
        id: figure.id,
        initialTitle: figure.title,
        initialDescription: figure.description,
        initialProject: figure.project,
      );
      return;
    }

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Figure 삭제'),
          content: Text('"$title"를 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );

      if (ok == true && context.mounted) {
        await context.read<FiguresVm>().deleteFigure(id);
      }
    }
  }
}