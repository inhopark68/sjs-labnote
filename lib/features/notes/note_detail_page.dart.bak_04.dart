import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_database.dart';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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
  bool _itemsLoading = true;

  bool _saving = false;
  bool _dirty = false;

  Note? _note;
  bool _noteIsDeleted = false;

  // ===== Items =====
  List<DbNoteReagent> _reagents = const [];
  List<DbNoteMaterial> _materials = const [];
  List<DbNoteReference> _references = const [];

  final ImagePicker _picker = ImagePicker();

  AppDatabase get _db => context.read<AppDatabase>();

  // ✅ 웹에서는 image_picker / mlkit 안정성 이슈가 많아서 숨김
  bool get _ocrSupported => !kIsWeb;

  @override
  void initState() {
    super.initState();

    _titleCtrl.addListener(_onTitleChanged);
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

  // =====================================================
  // Load / Save
  // =====================================================

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

    // ✅ 컨트롤러 값은 setState 밖에서 갱신 (리스너로 dirty 되지 않게)
    _titleCtrl
      ..removeListener(_onTitleChanged)
      ..text = noteAny?.title ?? ''
      ..addListener(_onTitleChanged);

    _bodyCtrl
      ..removeListener(_onBodyChanged)
      ..text = noteAny?.body ?? ''
      ..addListener(_onBodyChanged);

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

  void _onTitleChanged() {
    if (_noteIsDeleted) return;
    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  void _onBodyChanged() {
    if (_noteIsDeleted) return;
    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  void _markDirtyAndDebounceSave({required bool triggerRebuild}) {
    _dirty = true;

    if (triggerRebuild && mounted) {
      setState(() {}); // ✅ AppBar title 즉시 반영
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _saveIfNeeded();
    });
  }

  Future<void> _saveIfNeeded({bool force = false}) async {
    if (_noteLoading) return;
    if (_noteIsDeleted) return;
    if (!_dirty && !force) return;

    final title = _titleCtrl.text.trimRight();
    final body = _bodyCtrl.text.trimRight();

    if (mounted) setState(() => _saving = true);
    try {
      await _db.updateNote(
        id: widget.noteId,
        title: title,
        body: body,
      );
      _dirty = false;
      if (mounted) setState(() {}); // 상태칩 즉시 갱신
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =====================================================
  // Helpers
  // =====================================================

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _blockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제된 노트는 수정할 수 없습니다. 복원 후 수정하세요.')),
    );
  }

  void _ocrNotSupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OCR은 모바일(Android/iOS)에서만 지원됩니다.')),
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

  // =====================================================
  // OCR: capture + return text (dialogs call this)
  // =====================================================

  Future<String?> _runOcrAndReturnText() async {
    if (!_ocrSupported) {
      _ocrNotSupportedSnack();
      return null;
    }
    if (_noteIsDeleted) {
      _blockedSnack();
      return null;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    final raw = await _extractTextWithMlKit(picked.path);
    final text = _normalizeOcrText(raw);

    if (text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR 결과가 비어 있습니다. 더 선명한 이미지로 다시 시도해 주세요.')),
        );
      }
      return null;
    }

    return text;
  }

  Future<String> _extractTextWithMlKit(String imagePath) async {
    // 한글까지 강하게 원하면:
    // final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(input);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  String _normalizeOcrText(String raw) {
    return raw
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  // =====================================================
  // Add / Delete items
  //  - ✅ OCR 버튼은 "추가 다이얼로그 안"에만 존재
  // =====================================================

  Future<void> _addReagent() async {
    if (_noteIsDeleted) return _blockedSnack();

    final input = await showDialog<_ItemEntryInput?>(
      context: context,
      builder: (_) => _ItemEntryDialog(
        title: '시약 추가',
        enableOcr: _ocrSupported,
        onRequestOcrText: _runOcrAndReturnText,
      ),
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
      builder: (_) => _ItemEntryDialog(
        title: '재료 추가',
        enableOcr: _ocrSupported,
        onRequestOcrText: _runOcrAndReturnText,
      ),
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

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => _DoiEntryDialog(
        enableOcr: _ocrSupported,
        onRequestOcrText: _runOcrAndReturnText,
      ),
    );
    if (result == null) return;

    // 단일 DOI
    if (result is _DoiEntryInput) {
      await _db.noteItemsDao.insertReferenceRaw(
        id: _newId(),
        noteId: widget.noteId,
        doi: result.doi,
        memo: result.memo,
        createdAt: DateTime.now(),
      );
      await _loadAll();
      return;
    }

    // 다중 DOI
    if (result is List<_DoiEntryInput>) {
      for (final input in result) {
        await _db.noteItemsDao.insertReferenceRaw(
          id: _newId(),
          noteId: widget.noteId,
          doi: input.doi,
          memo: input.memo,
          createdAt: DateTime.now(),
        );
      }
      await _loadAll();
      return;
    }
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

  // =====================================================
  // UI helpers
  // =====================================================

  String _currentTitleForAppBar() {
    final t = _titleCtrl.text.trim();
    return t.isEmpty ? '(제목 없음)' : t;
  }

  Widget _saveStatusChip(BuildContext context) {
    final theme = Theme.of(context);

    // 저장중
    if (_saving) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          visualDensity: VisualDensity.compact,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('저장중…'),
            ],
          ),
        ),
      );
    }

    // 삭제 상태면 숨김(원하면 "읽기 전용"으로 표시 가능)
    if (_noteIsDeleted) return const SizedBox.shrink();

    // 저장 필요
    if (_dirty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          visualDensity: VisualDensity.compact,
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          backgroundColor: theme.colorScheme.primaryContainer,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.35)),
          labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('●', style: TextStyle(color: theme.colorScheme.primary)),
              const SizedBox(width: 8),
              const Text('저장 필요'),
            ],
          ),
        ),
      );
    }

    // 저장됨
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        label: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16),
            SizedBox(width: 6),
            Text('저장됨'),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required VoidCallback onAdd,
  }) {
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
          FilledButton.icon(
            onPressed: _noteIsDeleted ? _blockedSnack : onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('추가'),
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

  // =====================================================
  // Build
  // =====================================================

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
            _saveStatusChip(context),
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

              // ===== Note editor =====
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

              // ===== Items =====
              if (_itemsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // Reagents
                _sectionHeader(title: '시약 기록', onAdd: _addReagent),
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

                // Materials
                _sectionHeader(title: '재료 기록', onAdd: _addMaterial),
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

                // References
                _sectionHeader(title: 'References (DOI)', onAdd: _addReference),
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
// Dialog payload types + dialogs
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

/// ✅ "시약 추가 / 재료 추가" 공용 다이얼로그
/// - OCR 버튼이 다이얼로그 안에 존재
/// - OCR 결과에서 Cat/Lot/Company 자동 채움
/// - 여러 줄이면 name 후보 체크박스로 선택
class _ItemEntryDialog extends StatefulWidget {
  final String title;
  final bool enableOcr;
  final Future<String?> Function()? onRequestOcrText;

  const _ItemEntryDialog({
    required this.title,
    this.enableOcr = false,
    this.onRequestOcrText,
  });

  @override
  State<_ItemEntryDialog> createState() => _ItemEntryDialogState();
}

class _ItemEntryDialogState extends State<_ItemEntryDialog> {
  final _name = TextEditingController();
  final _catalog = TextEditingController();
  final _lot = TextEditingController();
  final _company = TextEditingController();
  final _memo = TextEditingController();

  bool _ocrRunning = false;

  // ✅ OCR 다중 후보
  List<String> _nameCandidates = const [];
  final Set<String> _selectedNames = <String>{};

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
    // ✅ 다중 후보가 있으면: 선택된 것 중 첫 번째를 대표 name으로 사용
    if (_nameCandidates.isNotEmpty) {
      final picked = _selectedNames.toList()..sort();
      if (picked.isEmpty) return;

      final first = picked.first;
      if (_name.text.trim().isEmpty) _name.text = first;

      final extra = picked.length > 1 ? picked.skip(1).join('\n') : '';
      if (extra.isNotEmpty && _memo.text.trim().isEmpty) {
        _memo.text = '추가 후보:\n$extra';
      }
    }

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

  // =====================================================
  // OCR parsing
  // =====================================================

  List<String> _lines(String text) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  _ParsedItem _parseItemFromOcr(String raw) {
    final text = raw.replaceAll('\r', '\n');
    final lines = _lines(text);

    String? cat;
    String? lot;
    String? company;
    final nameCandidates = <String>{};
    final memoLines = <String>[];

    String stripPrefix(String line) {
      final idx = line.indexOf(':');
      if (idx >= 0 && idx + 1 < line.length) {
        return line.substring(idx + 1).trim();
      }
      return line.trim();
    }

    bool looksLikeNoise(String s) {
      if (s.length < 2) return true;
      if (RegExp(r'^\d+$').hasMatch(s)) return true;
      return false;
    }

    for (final line in lines) {
      final lower = line.toLowerCase();

      // DOI는 name 후보에서 제외
      if (RegExp(r'\b10\.\d{4,9}/').hasMatch(line)) {
        memoLines.add(line);
        continue;
      }

      if (lower.startsWith('cat') || lower.startsWith('catalog')) {
        cat ??= stripPrefix(line);
        continue;
      }
      if (lower.startsWith('lot')) {
        lot ??= stripPrefix(line);
        continue;
      }
      if (lower.startsWith('company') || lower.startsWith('vendor') || lower.startsWith('supplier')) {
        company ??= stripPrefix(line);
        continue;
      }

      final cleaned = line.contains(':') ? stripPrefix(line) : line.trim();
      if (!looksLikeNoise(cleaned)) {
        nameCandidates.add(cleaned);
      } else {
        memoLines.add(line);
      }
    }

    final names = nameCandidates.toList();
    if (names.length > 30) names.removeRange(30, names.length);

    return _ParsedItem(
      catalog: cat,
      lot: lot,
      company: company,
      nameCandidates: names,
      memo: memoLines.isEmpty ? null : memoLines.join('\n'),
    );
  }

  Future<void> _runOcrFill() async {
    final fn = widget.onRequestOcrText;
    if (!widget.enableOcr || fn == null) return;

    setState(() => _ocrRunning = true);
    try {
      final raw = await fn();
      if (!mounted || raw == null) return;

      final parsed = _parseItemFromOcr(raw);

      if (_catalog.text.trim().isEmpty && (parsed.catalog ?? '').trim().isNotEmpty) {
        _catalog.text = parsed.catalog!.trim();
      }
      if (_lot.text.trim().isEmpty && (parsed.lot ?? '').trim().isNotEmpty) {
        _lot.text = parsed.lot!.trim();
      }
      if (_company.text.trim().isEmpty && (parsed.company ?? '').trim().isNotEmpty) {
        _company.text = parsed.company!.trim();
      }
      if (_memo.text.trim().isEmpty && (parsed.memo ?? '').trim().isNotEmpty) {
        _memo.text = parsed.memo!.trim();
      }

      final candidates = parsed.nameCandidates;
      if (candidates.isEmpty) {
        if (_memo.text.trim().isEmpty) _memo.text = raw.trim();
        return;
      }

      if (candidates.length == 1) {
        if (_name.text.trim().isEmpty) _name.text = candidates.first;
        setState(() {
          _nameCandidates = const [];
          _selectedNames.clear();
        });
        return;
      }

      setState(() {
        _nameCandidates = candidates;
        _selectedNames
          ..clear()
          ..addAll(candidates); // 기본 전체 선택
      });
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          if (widget.enableOcr)
            TextButton.icon(
              onPressed: _ocrRunning ? null : _runOcrFill,
              icon: _ocrRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined, size: 18),
              label: Text(_ocrRunning ? 'OCR중…' : 'OCR'),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_nameCandidates.isEmpty) ...[
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: '이름 *'),
                onSubmitted: (_) => _submit(),
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(child: Text('OCR로 여러 항목을 찾았습니다.\n추가할 항목을 선택하세요.')),
                  TextButton(
                    onPressed: () => setState(() => _selectedNames.addAll(_nameCandidates)),
                    child: const Text('전체 선택'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedNames.clear()),
                    child: const Text('전체 해제'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _nameCandidates.length,
                  itemBuilder: (_, i) {
                    final name = _nameCandidates[i];
                    final checked = _selectedNames.contains(name);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(name),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedNames.add(name);
                          } else {
                            _selectedNames.remove(name);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '대표 이름(선택)',
                  helperText: '선택 목록에서 첫 번째가 자동으로 들어갑니다. 필요하면 수정하세요.',
                ),
              ),
            ],
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
              maxLines: 4,
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

class _ParsedItem {
  final String? catalog;
  final String? lot;
  final String? company;
  final List<String> nameCandidates;
  final String? memo;

  const _ParsedItem({
    required this.catalog,
    required this.lot,
    required this.company,
    required this.nameCandidates,
    required this.memo,
  });
}

// =====================================================
// DOI Dialog (OCR + 자동추출 + 다중 선택)
// =====================================================

class _DoiEntryInput {
  final String doi;
  final String? memo;

  const _DoiEntryInput({
    required this.doi,
    this.memo,
  });
}

class _DoiEntryDialog extends StatefulWidget {
  final bool enableOcr;
  final Future<String?> Function()? onRequestOcrText;

  const _DoiEntryDialog({
    this.enableOcr = false,
    this.onRequestOcrText,
  });

  @override
  State<_DoiEntryDialog> createState() => _DoiEntryDialogState();
}

class _DoiEntryDialogState extends State<_DoiEntryDialog> {
  final _doiCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool _ocrRunning = false;

  // OCR에서 여러 DOI가 잡혔을 때 표시/선택용
  List<String> _candidates = const [];
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _doiCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _extractDoisFromText(String text) {
    final re = RegExp(r'\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b', caseSensitive: false);
    final found = <String>{};
    for (final m in re.allMatches(text)) {
      final doi = m.group(0)?.trim();
      if (doi != null && doi.isNotEmpty) found.add(doi);
    }
    final list = found.toList()..sort();
    return list;
  }

  Future<void> _runOcrAndExtract() async {
    final fn = widget.onRequestOcrText;
    if (!widget.enableOcr || fn == null) return;

    setState(() => _ocrRunning = true);
    try {
      final raw = await fn();
      if (!mounted || raw == null) return;

      final dois = _extractDoisFromText(raw);
      if (dois.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR 결과에서 DOI(10.xxxx/xxxx)를 찾지 못했습니다.')),
        );
        return;
      }

      if (dois.length == 1) {
        _doiCtrl.text = dois.first;
        setState(() {
          _candidates = const [];
          _selected.clear();
        });
        return;
      }

      setState(() {
        _candidates = dois;
        _selected
          ..clear()
          ..addAll(dois); // 기본: 전체 선택
      });
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  void _submit() {
    final memo = _clean(_memoCtrl);

    // 후보 리스트 모드: 체크된 것들 다중 반환
    if (_candidates.isNotEmpty) {
      final picked = _selected.toList()..sort();
      if (picked.isEmpty) return;

      Navigator.pop(
        context,
        picked.map((d) => _DoiEntryInput(doi: d, memo: memo)).toList(growable: false),
      );
      return;
    }

    // 단일 입력 모드
    final doi = _doiCtrl.text.trim();
    if (doi.isEmpty) return;

    Navigator.pop(context, _DoiEntryInput(doi: doi, memo: memo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('DOI 추가')),
          if (widget.enableOcr)
            TextButton.icon(
              onPressed: _ocrRunning ? null : _runOcrAndExtract,
              icon: _ocrRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.document_scanner_outlined, size: 18),
              label: Text(_ocrRunning ? 'OCR중…' : 'OCR'),
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_candidates.isEmpty) ...[
              TextField(
                controller: _doiCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'DOI * (예: 10.xxxx/xxxx)',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ] else ...[
              Row(
                children: [
                  const Expanded(
                    child: Text('OCR로 여러 DOI를 찾았습니다.\n추가할 DOI를 선택하세요.'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.addAll(_candidates)),
                    child: const Text('전체 선택'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('전체 해제'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _candidates.length,
                  itemBuilder: (_, i) {
                    final doi = _candidates[i];
                    final checked = _selected.contains(doi);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(doi),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(doi);
                          } else {
                            _selected.remove(doi);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(labelText: '메모(선택)'),
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