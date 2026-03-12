import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:labnote/data/app_database.dart';
import 'package:labnote/features/figures/figures_vm.dart';
import 'package:labnote/models/figure_panel_item.dart';

class FigureDetailScreen extends StatelessWidget {
  const FigureDetailScreen({
    super.key,
    required this.figureId,
    required this.title,
  });

  final int figureId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => FigureDetailVm(
        ctx.read<AppDatabase>(),
        figureId,
      )..load(),
      child: _FigureDetailBody(title: title),
    );
  }
}

class _FigureDetailBody extends StatelessWidget {
  const _FigureDetailBody({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FigureDetailVm>();
    final figure = vm.figure;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: Builder(
          builder: (context) {
            if (vm.loading && figure == null && vm.panels.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (figure != null) ...[
                  const _FigureMetaCard(),
                  const SizedBox(height: 16),
                  _FigurePreviewCard(
                    layoutType: figure.layoutType,
                    panels: vm.panels,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Panels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (vm.panels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('등록된 Panel이 없습니다.')),
                  )
                else
                  _ReorderablePanelList(panels: vm.panels),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '새 Panel',
        onPressed: () => _showCreatePanelDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreatePanelDialog(BuildContext context) async {
    final vm = context.read<FigureDetailVm>();
    final suggestedLabel = await vm.getNextPanelLabel();

    if (!context.mounted) return;

    final labelCtrl = TextEditingController(text: suggestedLabel);
    final titleCtrl = TextEditingController();
    final captionCtrl = TextEditingController();
    final noteIdCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 Panel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Panel label',
                  hintText: 'A',
                ),
              ),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(labelText: 'Caption'),
                maxLines: 3,
              ),
              TextField(
                controller: noteIdCtrl,
                decoration: const InputDecoration(labelText: 'Source note id'),
                keyboardType: TextInputType.number,
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
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;

    final panelLabel = labelCtrl.text.trim().toUpperCase();
    if (panelLabel.isEmpty) return;

    final sourceNoteId = int.tryParse(noteIdCtrl.text.trim());

    await context.read<FigureDetailVm>().createPanel(
          panelLabel: panelLabel,
          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
          caption:
              captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
          sourceNoteId: sourceNoteId,
        );
  }
}

class _FigureMetaCard extends StatelessWidget {
  const _FigureMetaCard();

  @override
  Widget build(BuildContext context) {
    final figure = context.watch<FigureDetailVm>().figure;
    if (figure == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Figure 정보', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _MetaRow(label: '제목', value: figure.title),
            _MetaRow(
              label: '프로젝트',
              value: (figure.project?.trim().isNotEmpty ?? false)
                  ? figure.project!
                  : '-',
            ),
            _MetaRow(
              label: '설명',
              value: (figure.description?.trim().isNotEmpty ?? false)
                  ? figure.description!
                  : '-',
            ),
            _MetaRow(label: '레이아웃', value: figure.layoutType),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigurePreviewCard extends StatelessWidget {
  const _FigurePreviewCard({
    required this.layoutType,
    required this.panels,
  });

  final String layoutType;
  final List<FigurePanelItem> panels;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            _FigureCanvas(
              layoutType: layoutType,
              panels: panels,
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureCanvas extends StatelessWidget {
  const _FigureCanvas({
    required this.layoutType,
    required this.panels,
  });

  final String layoutType;
  final List<FigurePanelItem> panels;

  @override
  Widget build(BuildContext context) {
    if (panels.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('패널이 없습니다.'),
      );
    }

    if (layoutType == 'column_1') {
      return Column(
        children: panels
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 180,
                  child: _PanelPreviewTile(panel: p),
                ),
              ),
            )
            .toList(),
      );
    }

    final crossAxisCount = 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: panels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: layoutType == 'grid_2x2' ? 1.05 : 1.2,
      ),
      itemBuilder: (context, index) {
        return _PanelPreviewTile(panel: panels[index]);
      },
    );
  }
}

class _PanelPreviewTile extends StatelessWidget {
  const _PanelPreviewTile({
    required this.panel,
  });

  final FigurePanelItem panel;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (panel.status) {
      case 'selected':
        badgeColor = Colors.blue;
        break;
      case 'final':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                child: Text(
                  panel.panelLabel,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  panel.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image_outlined,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            panel.title?.trim().isNotEmpty == true
                ? panel.title!
                : 'Panel ${panel.panelLabel}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (panel.sourceNoteId != null) ...[
            const SizedBox(height: 4),
            Text(
              'note ${panel.sourceNoteId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (panel.caption?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              panel.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReorderablePanelList extends StatelessWidget {
  const _ReorderablePanelList({
    required this.panels,
  });

  final List<FigurePanelItem> panels;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<FigureDetailVm>();

    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: panels.length,
      onReorder: (oldIndex, newIndex) async {
        final list = List<FigurePanelItem>.of(panels);

        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);

        await vm.reorderPanels(list.map((e) => e.id).toList());
      },
      itemBuilder: (context, index) {
        final panel = panels[index];

        return Card(
          key: ValueKey(panel.id),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(panel.panelLabel),
            ),
            title: Text(
              panel.title?.trim().isNotEmpty == true
                  ? panel.title!
                  : 'Panel ${panel.panelLabel}',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('status: ${panel.status}'),
                if (panel.sourceNoteId != null)
                  Text(
                    'source note: ${panel.sourceNoteId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: const Icon(Icons.drag_handle),
            onTap: () => _showPanelActions(context, panel.id),
          ),
        );
      },
    );
  }

  Future<void> _showPanelActions(BuildContext context, int panelId) async {
    final vm = context.read<FigureDetailVm>();
    final panel = vm.panels.firstWhere((e) => e.id == panelId);

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
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
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'edit') {
      await _showEditPanelDialog(
        context,
        id: panel.id,
        initialLabel: panel.panelLabel,
        initialTitle: panel.title,
        initialCaption: panel.caption,
        initialStatus: panel.status,
      );
      return;
    }

    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Panel 삭제'),
          content: Text('Panel ${panel.panelLabel}를 삭제할까요?'),
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
        await context.read<FigureDetailVm>().deletePanel(panel.id);
      }
    }
  }

  Future<void> _showEditPanelDialog(
    BuildContext context, {
    required int id,
    required String initialLabel,
    String? initialTitle,
    String? initialCaption,
    required String initialStatus,
  }) async {
    final labelCtrl = TextEditingController(text: initialLabel);
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final captionCtrl = TextEditingController(text: initialCaption ?? '');
    String status = initialStatus;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Panel 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Panel label'),
                ),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                TextField(
                  controller: captionCtrl,
                  decoration: const InputDecoration(labelText: 'Caption'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: '상태'),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('draft')),
                    DropdownMenuItem(
                      value: 'selected',
                      child: Text('selected'),
                    ),
                    DropdownMenuItem(value: 'final', child: Text('final')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      status = value;
                    });
                  },
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
      ),
    );

    if (ok != true) return;
    if (!context.mounted) return;

    final panelLabel = labelCtrl.text.trim();
    if (panelLabel.isEmpty) return;

    await context.read<FigureDetailVm>().updatePanel(
          id: id,
          panelLabel: panelLabel,
          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
          caption:
              captionCtrl.text.trim().isEmpty ? null : captionCtrl.text.trim(),
          status: status,
        );
  }
}