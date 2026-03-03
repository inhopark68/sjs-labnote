import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_database.dart'; // 경로 맞춰 수정

class ScanDetailPage extends StatelessWidget {
  final String scanId;
  const ScanDetailPage({super.key, required this.scanId});

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return FutureBuilder<ScanItem?>(
      future: db.getScan(scanId),
      builder: (context, snap) {
        final item = snap.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('스캔 상세'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: item == null
                    ? null
                    : () async {
                        await db.deleteScan(item.id);
                        if (context.mounted) Navigator.pop(context);
                      },
              ),
            ],
          ),
          body: snap.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? const Center(child: Text('항목을 찾을 수 없습니다.'))
              : _Body(item: item),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final ScanItem item;
  const _Body({required this.item});

  @override
  Widget build(BuildContext context) {
    final payload = _tryDecodeJson(item.payloadJson);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Chip(label: Text(item.kind.toUpperCase())),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title.isEmpty ? item.rawScanValue : item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
          Text(item.subtitle!, style: Theme.of(context).textTheme.bodyMedium),

        const SizedBox(height: 12),
        _kv('Identifier', item.identifier),
        _kv('URL', item.sourceUrl),
        _kv('Raw scan', item.rawScanValue),
        _kv('Created', item.createdAt.toString()),

        const SizedBox(height: 12),
        if (item.sourceUrl != null && item.sourceUrl!.startsWith('http'))
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(item.sourceUrl!);
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('URL을 열 수 없습니다.')));
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('링크 열기'),
          ),

        const SizedBox(height: 12),
        if (payload != null) ...[
          const Text(
            'Payload(JSON)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(payload),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _kv(String k, String? v) {
    if (v == null || v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Map<String, dynamic>? _tryDecodeJson(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.cast<String, dynamic>();
      return {'value': v};
    } catch (_) {
      return null;
    }
  }
}
