import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String preview;
  final DateTime updatedAt;

  final bool isPinned;
  final bool isLocked;
  final bool hasExpiredReagent;
  final bool hasExpiringSoon;

  final int attachmentCount;
  final int reagentCount;
  final int cellCount;
  final int equipmentCount;

  final List<String> tagNames;

  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.title,
    required this.preview,
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
    required this.onTap,
    this.onPinToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasStatus =
        isLocked || hasExpiredReagent || hasExpiringSoon || isPinned;
    final hasTags = tagNames.isNotEmpty;

    final status = <Widget>[
      if (isLocked) const _StatusPill(icon: Icons.lock, text: 'LOCK'),
      if (hasExpiredReagent)
        const _StatusPill(icon: Icons.warning_amber, text: 'EXPIRED'),
      if (!hasExpiredReagent && hasExpiringSoon)
        const _StatusPill(icon: Icons.schedule, text: 'SOON'),
      if (isPinned) const _StatusPill(icon: Icons.push_pin, text: 'PIN'),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias, // ✅ Ink ripple이 카드 밖으로 안 나가게
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 1) 제목 + 액션 =====
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Untitled' : title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, // ✅ 살짝 강조
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  if (onPinToggle != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: isPinned ? 'Unpin' : 'Pin',
                      onPressed: onPinToggle,
                      icon: Icon(
                        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      ),
                    ),

                  if (onDelete != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // ===== 2) 미리보기 =====
              Text(
                preview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ===== 3) 상태(있을 때만) =====
              if (hasStatus) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: status),
              ],

              // ===== 4) 태그(있을 때만) =====
              if (hasTags) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: tagNames
                      .take(3)
                      .map((t) => _TagPill(text: t))
                      .toList(),
                ),
              ],

              const SizedBox(height: 10),

              // ===== 5) 메타 + 시간 =====
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (attachmentCount > 0)
                          _MetaPill(
                            icon: Icons.attachment,
                            text: attachmentCount.toString(),
                          ),
                        if (reagentCount > 0)
                          _MetaPill(
                            icon: Icons.science,
                            text: reagentCount.toString(),
                          ),
                        if (cellCount > 0)
                          _MetaPill(
                            icon: Icons.biotech,
                            text: cellCount.toString(),
                          ),
                        if (equipmentCount > 0)
                          _MetaPill(
                            icon: Icons.memory,
                            text: equipmentCount.toString(),
                          ),
                        // ✅ 전부 0이면 “0들”을 보여주지 않도록 (메인 화면이 훨씬 정돈됨)
                        if (attachmentCount == 0 &&
                            reagentCount == 0 &&
                            cellCount == 0 &&
                            equipmentCount == 0)
                          _MetaPill(icon: Icons.info_outline, text: '메타 없음'),
                      ],
                    ),
                  ),

                  // ✅ 상대 시간 + 툴팁에 절대 시간
                  Tooltip(
                    message: _fmt(updatedAt),
                    child: Text(
                      _relative(updatedAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  // ✅ 패키지 없이 간단 상대시간
  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    // 7일 이상은 절대 날짜로
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }
}

/// ✅ 상태는 Chip 대신 “작은 pill”로: 메인 카드에서 더 가볍고 정보 위계가 좋아짐
class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StatusPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  const _TagPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: theme.textTheme.labelMedium),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
