import 'package:flutter/material.dart';

class MaterialRowItem {
  final String id;
  final String title;
  final String subtitle;
  final bool warnExpired;
  final bool warnSoon;

  const MaterialRowItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.warnExpired = false,
    this.warnSoon = false,
  });
}

class MaterialsSection extends StatelessWidget {
  final List<MaterialRowItem> reagents;
  final List<MaterialRowItem> cells;
  final List<MaterialRowItem> equipments;

  final VoidCallback onAddReagent;
  final VoidCallback onAddCell;
  final VoidCallback onAddEquipment;

  final void Function(String id)? onRemoveReagent;
  final void Function(String id)? onRemoveCell;
  final void Function(String id)? onRemoveEquipment;

  const MaterialsSection({
    super.key,
    required this.reagents,
    required this.cells,
    required this.equipments,
    required this.onAddReagent,
    required this.onAddCell,
    required this.onAddEquipment,
    this.onRemoveReagent,
    this.onRemoveCell,
    this.onRemoveEquipment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Section(
          icon: Icons.science,
          title: '시약',
          onAction: onAddReagent,
          children: reagents.isEmpty
              ? [const _Hint('연결된 시약이 없습니다.')]
              : reagents.map((e) => _MaterialTile(item: e, onRemove: onRemoveReagent == null ? null : () => onRemoveReagent!(e.id))),
        ),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.biotech,
          title: '세포',
          onAction: onAddCell,
          children: cells.isEmpty
              ? [const _Hint('연결된 세포가 없습니다.')]
              : cells.map((e) => _MaterialTile(item: e, onRemove: onRemoveCell == null ? null : () => onRemoveCell!(e.id))),
        ),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.memory,
          title: '장비',
          onAction: onAddEquipment,
          children: equipments.isEmpty
              ? [const _Hint('연결된 장비가 없습니다.')]
              : equipments.map((e) => _MaterialTile(item: e, onRemove: onRemoveEquipment == null ? null : () => onRemoveEquipment!(e.id))),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAction;
  final Iterable<Widget> children;

  const _Section({required this.icon, required this.title, required this.onAction, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: const Text('추가')),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final MaterialRowItem item;
  final VoidCallback? onRemove;
  const _MaterialTile({required this.item, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (item.warnExpired) const _Badge(text: 'EXPIRED', icon: Icons.warning_amber),
      if (!item.warnExpired && item.warnSoon) const _Badge(text: 'SOON', icon: Icons.schedule),
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.subtitle.isNotEmpty) Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (badges.isNotEmpty) const SizedBox(height: 6),
          if (badges.isNotEmpty) Wrap(spacing: 8, children: badges),
        ],
      ),
      trailing: onRemove == null ? null : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Badge({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(text),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
      ),
    );
  }
}
