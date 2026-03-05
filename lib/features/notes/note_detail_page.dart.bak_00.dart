import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart';

class NoteDetailPage extends StatefulWidget {
  final int noteId;
  const NoteDetailPage({super.key, required this.noteId});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  // ===== Note fields (editable) =====
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  Timer? _debounce;
  bool _noteLoading = true;
  bool _saving = false;
  bool _dirty = false;

  Note? _note;
  bool _noteIsDeleted = false;

  // ===== Items =====
  List<DbNoteReagent> _reagents = const [];
  List<DbNoteMaterial> _materials = const [];
  List<DbNoteReference> _references = const [];
  bool _itemsLoading = true;

  AppDatabase get _db => context.read<AppDatabase>();

  @override
  void initState() {
    super.initState();

    _titleCtrl.addListener(_onTitleChanged); // ✅ AppBar 즉시 갱신
    _bodyCtrl.addListener(_onBodyChanged);

    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_noteIsDeleted) return;
    // ✅ AppBar 제목 즉시 갱신 (입력마다 setState)
    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  void _onBodyChanged() {
    if (_noteIsDeleted) return;
    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  void _markDirtyAndDebounceSave({required bool triggerRebuild}) {
    _dirty = true;

    if (triggerRebuild && mounted) {
      setState(() {}); // AppBar title 즉시 반영
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _saveIfNeeded();
    });
  }

  Future<void> _loadAll() async {
    setState(() {
      _noteLoading = true;
      _itemsLoading = true;
    });

    final noteAny = await _db.getNoteAny(widget.noteId);
    final isDeleted = noteAny?.isDeleted ?? true;

    final reagents = await _db.noteItemsDao.listReagents(widget.noteId);
    final materials = await _db.noteItemsDao.listMaterials(widget.noteId);
    final refs = await _db.noteItemsDao.listReferences(widget.noteId);

    if (!mounted) return;

    _note = noteAny;
    _noteIsDeleted = isDeleted;

    _titleCtrl.text = noteAny?.title ?? '';
    _bodyCtrl.text = noteAny?.body ?? '';
    _dirty = false;

    setState(() {
      _reagents = reagents;
      _materials = materials;
      _references = refs;
      _noteLoading = false;
      _itemsLoading = false;
    });
  }

  Future<void> _refresh() => _loadAll();

  Future<void> _saveIfNeeded({bool force = false}) async {
    if (_noteLoading) return;
    if (_noteIsDeleted) return;
    if (!_dirty && !force) return;

    final title = _titleCtrl.text.trimRight();
    final body = _bodyCtrl.text.trimRight();

    setState(() => _saving = true);
    try {
      await _db.updateNote(
        id: widget.noteId,
        title: title,
        body: body,
      );
      _dirty = false;
      if (mounted) setState(() {}); // ✅ 저장 후 AppBar 상태(●) 갱신
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== Helpers =====

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _blockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제된 노트는 수정할 수 없습니다. 복원 후 수정하세요.')),
    );
  }

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
      message: '이 노트를 완전히 삭제할까요?\n노트에 연결된 시약/재료/DOI 기록도 함께 삭제되며, 복구할 수 없습니다.',
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

  // ===== Add / Delete items =====

  Future<void> _addReagent() async {
    if (_noteIsDeleted) return _blockedSnack();

    final input = await showDialog<_ItemEntryInput?>(
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

    final input = await showDialog<_ItemEntryInput?>(
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

    final input = await showDialog<_DoiEntryInput?>(
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

  // ===== ✅ AppBar 상태 표시 =====

  String _currentTitleForAppBar() {
    final t = _titleCtrl.text.trim();
    return t.isEmpty ? '(제목 없음)' : t;
  }

  Widget _saveStatusChip() {
    // 저장중 > 저장필요 > 저장됨 순
    if (_saving) {
      return const Padding(
        padding: EdgeInsets.only(right: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_noteIsDeleted) {
      return const SizedBox.shrink();
    }
    if (_dirty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          visualDensity: VisualDensity.compact,
          label: const Text('저장 필요'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        label: const Text('저장됨'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_noteLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        await _saveIfNeeded(force: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitleForAppBar()),
          actions: [
            _saveStatusChip(),

            TextButton.icon(
              onPressed: (_noteIsDeleted || _saving) ? null : () => _saveIfNeeded(force: true),
              icon: const Icon(Icons.save),
              label: const Text('저장'),
            ),

            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
            ),

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
              if (_noteIsDeleted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('이 노트는 삭제 상태입니다. 복원하면 제목/내용과 시약/재료/DOI를 다시 수정할 수 있습니다.'),
                    ),
                  ),
                ),

              // ===== 노트 본문 입력 영역 =====
              TextField(
                controller: _titleCtrl,
                enabled: !_noteIsDeleted,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                enabled: !_noteIsDeleted,
                decoration: const InputDecoration(
                  labelText: '연구 내용',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 16),
              const Divider(height: 32),

              // ===== 기존 아이템 섹션들 =====
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
                        subtitle: Text(_subtitleParts(
                          company: r.company,
                          cat: r.catalogNumber,
                          lot: r.lotNumber,
                          memo: r.memo,
                        )),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _noteIsDeleted ? _blockedSnack : () => _deleteReagent(r.id),
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
                        subtitle: Text(_subtitleParts(
                          company: m.company,
                          cat: m.catalogNumber,
                          lot: m.lotNumber,
                          memo: m.memo,
                        )),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _noteIsDeleted ? _blockedSnack : () => _deleteMaterial(m.id),
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
                          onPressed: _noteIsDeleted ? _blockedSnack : () => _deleteReference(r.id),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Dialog payload types + dialogs (기존 그대로)
// =====================================================

class _ItemEntryInput {
  final String name;
  final String? catalogNumber;
  final String? lotNumber;
  final String? company;
  final String? memo;

  const _ItemEntryInput({
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
  final _catalog = TextEditingController();
  final _lot = TextEditingController();
  final _company = TextEditingController();
  final _memo = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _catalog.dispose();
    _lot.dispose();
    _company.dispose();
    _memo.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      _ItemEntryInput(
        name: name,
        catalogNumber: _clean(_catalog),
        lotNumber: _clean(_lot),
        company: _clean(_company),
        memo: _clean(_memo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '이름 *'),
              onSubmitted: (_) => _submit(),
            ),
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: '회사'),
            ),
            TextField(
              controller: _catalog,
              decoration: const InputDecoration(labelText: 'Catalog No.'),
            ),
            TextField(
              controller: _lot,
              decoration: const InputDecoration(labelText: 'Lot No.'),
            ),
            TextField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _DoiEntryInput {
  final String doi;
  final String? memo;

  const _DoiEntryInput({
    required this.doi,
    this.memo,
  });
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

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  void _submit() {
    final doi = _doi.text.trim();
    if (doi.isEmpty) return;

    Navigator.pop(
      context,
      _DoiEntryInput(
        doi: doi,
        memo: _clean(_memo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('DOI 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _doi,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'DOI * (예: 10.xxxx/xxxx)'),
              onSubmitted: (_) => _submit(),
            ),
            TextField(
              controller: _memo,
              decoration: const InputDecoration(labelText: '메모'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('추가'),
        ),
      ],
    );
  }
}