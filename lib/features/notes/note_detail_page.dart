import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart'; // 경로 맞게 조정하세요

class NoteDetailPage extends StatefulWidget {
  final String noteId;
  const NoteDetailPage({super.key, required this.noteId});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  // 노트 본문(삭제 여부 상관없이 표시)
  Note? _note;
  bool _noteLoading = true;

  // 연결 항목들
  List<DbNoteReagent> _reagents = const [];
  List<DbNoteMaterial> _materials = const [];
  List<DbNoteReference> _references = const [];
  bool _itemsLoading = true;

  // 삭제 상태(soft delete)면 편집 차단 + 메뉴 변경
  bool _noteIsDeleted = false;

  AppDatabase get _db => context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAll);
  }

  Future<void> _loadAll() async {
    setState(() {
      _noteLoading = true;
      _itemsLoading = true;
    });

    // ✅ 삭제 여부 상관없이 노트 로드
    final noteAny = await _db.getNoteAny(widget.noteId);
    final isDeleted = noteAny?.isDeleted ?? true; // 없으면 삭제 취급

    // ✅ 항목 로드(노트가 없어도 noteId 기준으로 존재할 수 있으니 로드)
    final dao = _db.noteItemsDao;
    final reagents = await dao.listReagents(widget.noteId);
    final materials = await dao.listMaterials(widget.noteId);
    final refs = await dao.listReferences(widget.noteId);

    if (!mounted) return;
    setState(() {
      _note = noteAny;
      _noteIsDeleted = isDeleted;
      _reagents = reagents;
      _materials = materials;
      _references = refs;
      _noteLoading = false;
      _itemsLoading = false;
    });
  }

  Future<void> _refresh() => _loadAll();

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _blockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제된 노트는 수정할 수 없습니다. 복원 후 수정하세요.')),
    );
  }

  // =========================================================
  // Note menu actions
  // =========================================================

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    required String okText,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okText),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _moveToTrash() async {
    final ok = await _confirmDialog(
      title: '휴지통으로 이동',
      message: '이 노트를 휴지통으로 이동할까요?\n(완전 삭제가 아니며, 복원할 수 있습니다.)',
      okText: '이동',
    );
    if (!ok) return;

    try {
      await _db.deleteNote(widget.noteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴지통으로 이동했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이동 실패: $e')),
      );
    }
  }

  Future<void> _restoreFromTrash() async {
    final ok = await _confirmDialog(
      title: '복원',
      message: '이 노트를 복원할까요?',
      okText: '복원',
    );
    if (!ok) return;

    try {
      await _db.restoreNote(widget.noteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트를 복원했습니다.')),
      );
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복원 실패: $e')),
      );
    }
  }

  Future<void> _confirmHardDelete() async {
    final ok = await _confirmDialog(
      title: '완전 삭제',
      message:
          '이 노트를 완전히 삭제할까요?\n노트에 연결된 시약/재료/DOI 기록도 함께 삭제되며, 복구할 수 없습니다.',
      okText: '완전 삭제',
    );
    if (!ok) return;

    try {
      await _db.hardDeleteNote(widget.noteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트를 완전 삭제했습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('완전 삭제 실패: $e')),
      );
    }
  }

  // =========================================================
  // Add dialogs
  // =========================================================

  Future<void> _addReagent() async {
    if (_noteIsDeleted) return _blockedSnack();

    final input = await showDialog<_ItemEntryInput>(
      context: context,
      builder: (_) => const _ItemEntryDialog(title: '시약 추가'),
    );
    if (input == null) return;

    await _db.noteItemsDao.insertReagentRaw(
      id: _newId(),
      noteId: widget.noteId,
      name: input.name,
      catalogNumber: input.catalogNumber,
      lotNumber: input.lotNumber,
      company: input.company,
      memo: input.memo,
      createdAt: DateTime.now(),
    );

    await _loadAll();
  }

  Future<void> _addMaterial() async {
    if (_noteIsDeleted) return _blockedSnack();

    final input = await showDialog<_ItemEntryInput>(
      context: context,
      builder: (_) => const _ItemEntryDialog(title: '재료 추가'),
    );
    if (input == null) return;

    await _db.noteItemsDao.insertMaterialRaw(
      id: _newId(),
      noteId: widget.noteId,
      name: input.name,
      catalogNumber: input.catalogNumber,
      lotNumber: input.lotNumber,
      company: input.company,
      memo: input.memo,
      createdAt: DateTime.now(),
    );

    await _loadAll();
  }

  Future<void> _addReference() async {
    if (_noteIsDeleted) return _blockedSnack();

    final input = await showDialog<_DoiEntryInput>(
      context: context,
      builder: (_) => const _DoiEntryDialog(),
    );
    if (input == null) return;

    await _db.noteItemsDao.insertReferenceRaw(
      id: _newId(),
      noteId: widget.noteId,
      doi: input.doi,
      memo: input.memo,
      createdAt: DateTime.now(),
    );

    await _loadAll();
  }

  // =========================================================
  // Delete handlers
  // =========================================================

  Future<void> _deleteReagent(String id) async {
    if (_noteIsDeleted) return _blockedSnack();
    await _db.noteItemsDao.deleteReagent(id);
    await _loadAll();
  }

  Future<void> _deleteMaterial(String id) async {
    if (_noteIsDeleted) return _blockedSnack();
    await _db.noteItemsDao.deleteMaterial(id);
    await _loadAll();
  }

  Future<void> _deleteReference(String id) async {
    if (_noteIsDeleted) return _blockedSnack();
    await _db.noteItemsDao.deleteReference(id);
    await _loadAll();
  }

  // =========================================================
  // UI helpers
  // =========================================================

  Widget _sectionHeader(String title, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: _noteIsDeleted ? _blockedSnack : onAdd,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '$title 추가',
          ),
        ],
      ),
    );
  }

  String _subtitleParts({
    String? company,
    String? cat,
    String? lot,
    String? memo,
  }) {
    final parts = <String>[];
    if (company != null && company.trim().isNotEmpty) parts.add(company.trim());
    if (cat != null && cat.trim().isNotEmpty) parts.add('Cat: ${cat.trim()}');
    if (lot != null && lot.trim().isNotEmpty) parts.add('Lot: ${lot.trim()}');
    if (memo != null && memo.trim().isNotEmpty) parts.add(memo.trim());
    return parts.join(' · ');
  }

  Widget _noteCard() {
    if (_noteLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_note == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text('노트를 찾을 수 없습니다.'),
      );
    }
    return Card(
      child: ListTile(
        title: Text(_note!.title.isEmpty ? '(제목 없음)' : _note!.title),
        subtitle: Text(_note!.body),
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('노트 상세'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),

          // ✅ 오른쪽 상단 메뉴(⋮): 상태에 따라 메뉴 구성이 달라짐
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'trash':
                  _moveToTrash();
                  break;
                case 'restore':
                  _restoreFromTrash();
                  break;
                case 'hard_delete':
                  _confirmHardDelete();
                  break;
              }
            },
            itemBuilder: (context) {
              if (_noteIsDeleted) {
                return const [
                  PopupMenuItem(value: 'restore', child: Text('복원')),
                  PopupMenuItem(value: 'hard_delete', child: Text('완전 삭제')),
                ];
              }
              return const [
                PopupMenuItem(value: 'trash', child: Text('휴지통으로 이동')),
                PopupMenuItem(value: 'hard_delete', child: Text('완전 삭제')),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ✅ 삭제 상태 안내 배너
            if (_noteIsDeleted)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '이 노트는 삭제 상태입니다. 복원하면 시약/재료/DOI를 다시 수정할 수 있습니다.',
                    ),
                  ),
                ),
              ),

            // ✅ 제목/본문 표시(삭제 노트도 표시)
            _noteCard(),

            // ✅ 시약/재료/DOI 섹션
            if (_itemsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _sectionHeader('시약 기록', _addReagent),
              if (_reagents.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('등록된 시약이 없습니다.'),
                )
              else
                ..._reagents.map(
                  (r) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(r.name),
                      subtitle: Text(
                        _subtitleParts(
                          company: r.company,
                          cat: r.catalogNumber,
                          lot: r.lotNumber,
                          memo: r.memo,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _noteIsDeleted
                            ? _blockedSnack
                            : () => _deleteReagent(r.id),
                      ),
                    ),
                  ),
                ),

              _sectionHeader('재료 기록', _addMaterial),
              if (_materials.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('등록된 재료가 없습니다.'),
                )
              else
                ..._materials.map(
                  (m) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(m.name),
                      subtitle: Text(
                        _subtitleParts(
                          company: m.company,
                          cat: m.catalogNumber,
                          lot: m.lotNumber,
                          memo: m.memo,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _noteIsDeleted
                            ? _blockedSnack
                            : () => _deleteMaterial(m.id),
                      ),
                    ),
                  ),
                ),

              _sectionHeader('References (DOI)', _addReference),
              if (_references.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('등록된 DOI가 없습니다.'),
                )
              else
                ..._references.map(
                  (r) => Card(
                    child: ListTile(
                      dense: true,
                      title: Text(r.doi),
                      subtitle: Text((r.memo ?? '').trim()),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: _noteIsDeleted
                            ? _blockedSnack
                            : () => _deleteReference(r.id),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// =========================================================
// Dialogs
// =========================================================

class _ItemEntryInput {
  final String name;
  final String? catalogNumber;
  final String? lotNumber;
  final String? company;
  final String? memo;

  _ItemEntryInput({
    required this.name,
    this.catalogNumber,
    this.lotNumber,
    this.company,
    this.memo,
  });
}

class _ItemEntryDialog extends StatefulWidget {
  final String title;
  const _ItemEntryDialog({required this.title});

  @override
  State<_ItemEntryDialog> createState() => _ItemEntryDialogState();
}

class _ItemEntryDialogState extends State<_ItemEntryDialog> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _cat = TextEditingController();
  final _lot = TextEditingController();
  final _memo = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _cat.dispose();
    _lot.dispose();
    _memo.dispose();
    super.dispose();
  }

  String? _n(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름 *'),
              autofocus: true,
            ),
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: '제품회사명'),
            ),
            TextField(
              controller: _cat,
              decoration: const InputDecoration(labelText: '카탈로그 번호'),
            ),
            TextField(
              controller: _lot,
              decoration: const InputDecoration(labelText: 'Lot 번호'),
            ),
            TextField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;

            Navigator.pop(
              context,
              _ItemEntryInput(
                name: name,
                company: _n(_company.text),
                catalogNumber: _n(_cat.text),
                lotNumber: _n(_lot.text),
                memo: _n(_memo.text),
              ),
            );
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _DoiEntryInput {
  final String doi;
  final String? memo;
  _DoiEntryInput({required this.doi, this.memo});
}

class _DoiEntryDialog extends StatefulWidget {
  const _DoiEntryDialog();

  @override
  State<_DoiEntryDialog> createState() => _DoiEntryDialogState();
}

class _DoiEntryDialogState extends State<_DoiEntryDialog> {
  final _doi = TextEditingController();
  final _memo = TextEditingController();

  @override
  void dispose() {
    _doi.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('DOI 추가'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _doi,
              decoration: const InputDecoration(
                labelText: 'DOI *',
                hintText: '예) 10.1038/s41586-020-2649-2',
              ),
              autofocus: true,
            ),
            TextField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            final doi = _doi.text.trim();
            if (doi.isEmpty) return;

            final memo = _memo.text.trim().isNotEmpty ? _memo.text.trim() : null;
            Navigator.pop(context, _DoiEntryInput(doi: doi, memo: memo));
          },
          child: const Text('저장'),
        ),
      ],
    );
  }
}