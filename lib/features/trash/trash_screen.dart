import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart';
import '../notes/note_detail_page.dart.bak';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  List<Note> _items = const [];

  AppDatabase get _db => context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();

    Future.microtask(_load);

    _searchCtrl.addListener(() {
      _load(); // 타이핑마다 즉시 갱신(가벼운 앱이면 OK)
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final items = await _db.listDeletedNotes(query: _searchCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _restore(int id) async {
    await _db.restoreNote(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('복원했습니다.')));

    await _load();
  }

  Future<void> _hardDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('완전 삭제'),
        content: const Text(
          '이 노트를 완전히 삭제할까요?\n'
          '연결된 시약/재료/DOI 기록도 함께 삭제되며, 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('완전 삭제'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _db.hardDeleteNote(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('완전 삭제했습니다.')));

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('휴지통'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '휴지통 검색 (제목/본문)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('휴지통이 비어 있습니다.'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final n = _items[i];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(n.title.isEmpty ? '(제목 없음)' : n.title),
                              subtitle: Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoteDetailPage(noteId: n.id),
                                  ),
                                );
                                await _load();
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'restore') _restore(n.id);
                                  if (v == 'hard') _hardDelete(n.id);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'restore',
                                    child: Text('복원'),
                                  ),
                                  PopupMenuItem(
                                    value: 'hard',
                                    child: Text('완전 삭제'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}