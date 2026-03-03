import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart'; // 경로 맞춰 수정
import 'scan_detail_page.dart';
import 'scan_page.dart';

class ScansListPage extends StatefulWidget {
  const ScansListPage({super.key});

  @override
  State<ScansListPage> createState() => _ScansListPageState();
}

class _ScansListPageState extends State<ScansListPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    if (mounted) setState(() {}); // 돌아오면 목록 새로고침
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('스캔 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _query,
              decoration: InputDecoration(
                hintText: '검색 (제목/식별자/원문)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _query.clear()),
                      ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ScanItem>>(
              future: db.listScans(query: _query.text),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? const <ScanItem>[];
                if (items.isEmpty) {
                  return const Center(child: Text('스캔 기록이 없습니다.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final s = items[i];
                    return ListTile(
                      leading: _KindChip(kind: s.kind),
                      title: Text(
                        s.title.isEmpty ? s.rawScanValue : s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (s.subtitle != null &&
                              s.subtitle!.trim().isNotEmpty)
                            s.subtitle!.trim(),
                          if (s.identifier != null &&
                              s.identifier!.trim().isNotEmpty)
                            s.identifier!.trim(),
                        ].join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanDetailPage(scanId: s.id),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScan,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('스캔'),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String kind;
  const _KindChip({required this.kind});

  @override
  Widget build(BuildContext context) {
    final label = kind.toUpperCase();
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}
