import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../data/app_database.dart';

// =====================================================
// Quill 저장/복원 유틸
// =====================================================

Set<String> extractImagePathsFromDoc(quill.QuillController c) {
  final paths = <String>{};
  for (final op in c.document.toDelta().toList()) {
    final data = op.data;
    if (data is Map && data['image'] is String) {
      paths.add(data['image'] as String);
    }
  }
  return paths;
}

String encodeDoc(quill.QuillController c) {
  final json = c.document.toDelta().toJson();
  return jsonEncode(json);
}

String quillStoredTextToPlain(String? encodedOrText) {
  final raw = (encodedOrText ?? '').trim();
  if (raw.isEmpty) return '';

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        return doc.toPlainText().replaceAll('\n', ' ').trim();
      }
    } catch (_) {}
  }

  return raw.replaceAll('\n', ' ').trim();
}

void decodeDocOrPlainText(quill.QuillController c, String? encodedOrText) {
  final raw = (encodedOrText ?? '').trim();

  if (raw.isEmpty) {
    c.document = quill.Document()..insert(0, '');
    c.updateSelection(
      const TextSelection.collapsed(offset: 0),
      quill.ChangeSource.local,
    );
    return;
  }

  if (raw.startsWith('[')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        c.document = doc;
        c.updateSelection(
          const TextSelection.collapsed(offset: 0),
          quill.ChangeSource.local,
        );
        return;
      }
    } catch (_) {
      // plain text fallback
    }
  }

  c.document = quill.Document()..insert(0, raw);
  c.updateSelection(
    const TextSelection.collapsed(offset: 0),
    quill.ChangeSource.local,
  );
}

// =====================================================
// Item dialog payload
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

// =====================================================
// Item dialog
// =====================================================

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
    if (_nameCandidates.isNotEmpty) {
      final picked = _selectedNames.toList()..sort();
      if (picked.isEmpty) return;

      final first = picked.first;
      if (_name.text.trim().isEmpty) {
        _name.text = first;
      }

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
      if (lower.startsWith('company') ||
          lower.startsWith('vendor') ||
          lower.startsWith('supplier')) {
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
    if (names.length > 30) {
      names.removeRange(30, names.length);
    }

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

      if (_catalog.text.trim().isEmpty &&
          (parsed.catalog ?? '').trim().isNotEmpty) {
        _catalog.text = parsed.catalog!.trim();
      }
      if (_lot.text.trim().isEmpty && (parsed.lot ?? '').trim().isNotEmpty) {
        _lot.text = parsed.lot!.trim();
      }
      if (_company.text.trim().isEmpty &&
          (parsed.company ?? '').trim().isNotEmpty) {
        _company.text = parsed.company!.trim();
      }
      if (_memo.text.trim().isEmpty && (parsed.memo ?? '').trim().isNotEmpty) {
        _memo.text = parsed.memo!.trim();
      }

      final candidates = parsed.nameCandidates;
      if (candidates.isEmpty) {
        if (_memo.text.trim().isEmpty) {
          _memo.text = raw.trim();
        }
        return;
      }

      if (candidates.length == 1) {
        if (_name.text.trim().isEmpty) {
          _name.text = candidates.first;
        }
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
          ..addAll(candidates);
      });
    } finally {
      if (mounted) {
        setState(() => _ocrRunning = false);
      }
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
                  const Expanded(
                    child: Text('OCR로 여러 항목을 찾았습니다.\n추가할 항목을 선택하세요.'),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _selectedNames.addAll(_nameCandidates)),
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
// DOI dialog payload
// =====================================================

class _DoiEntryInput {
  final String doi;
  final String? memo;

  const _DoiEntryInput({
    required this.doi,
    this.memo,
  });
}

// =====================================================
// DOI dialog
// =====================================================

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
    final re = RegExp(
      r'\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b',
      caseSensitive: false,
    );

    final found = <String>{};
    for (final m in re.allMatches(text)) {
      final doi = m.group(0)?.trim();
      if (doi != null && doi.isNotEmpty) {
        found.add(doi);
      }
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
          const SnackBar(
            content: Text('OCR 결과에서 DOI(10.xxxx/xxxx)를 찾지 못했습니다.'),
          ),
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
          ..addAll(dois);
      });
    } finally {
      if (mounted) {
        setState(() => _ocrRunning = false);
      }
    }
  }

  void _submit() {
    final memo = _clean(_memoCtrl);

    if (_candidates.isNotEmpty) {
      final picked = _selected.toList()..sort();
      if (picked.isEmpty) return;

      Navigator.pop(
        context,
        picked
            .map((d) => _DoiEntryInput(doi: d, memo: memo))
            .toList(growable: false),
      );
      return;
    }

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

// =====================================================
// Page
// =====================================================

class NoteDetailPage extends StatefulWidget {
  final int noteId;

  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _SelectableImageEmbedBuilder implements quill.EmbedBuilder {
  final quill.EmbedBuilder baseBuilder;
  final Future<void> Function(String imagePath) onTapImage;

  const _SelectableImageEmbedBuilder({
    required this.baseBuilder,
    required this.onTapImage,
  });

  @override
  String get key => 'image';

  @override
  bool get expanded => baseBuilder.expanded;

  @override
  String toPlainText(quill.Embed node) => baseBuilder.toPlainText(node);

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return baseBuilder.buildWidgetSpan(widget);
  }

  @override
  Widget build(
    BuildContext context,
    quill.EmbedContext embedContext,
  ) {
    final node = embedContext.node;
    final imagePath = node.value.data.toString();

    final child = baseBuilder.build(context, embedContext);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTapImage(imagePath),
      child: child,
    );
  }
}

class _NoteDetailPageState extends State<NoteDetailPage>
    with WidgetsBindingObserver {
  AppDatabase get _db => context.read<AppDatabase>();

  final quill.QuillController _titleQuill = quill.QuillController.basic();
  final quill.QuillController _bodyQuill = quill.QuillController.basic();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();

  final ScrollController _titleScroll = ScrollController();
  final ScrollController _bodyScroll = ScrollController();

  final ImagePicker _picker = ImagePicker();

  Timer? _debounce;

  bool _noteLoading = true;
  bool _itemsLoading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _noteIsDeleted = false;
  bool _suppressEditorListener = false;
  bool _cleanupRunning = false;

  DateTime? _lastSavedAt;

  Note? _note;

  bool get _ocrSupported => !kIsWeb;
  bool get _imageInsertSupported => !kIsWeb;

  List<DbNoteReagent> _reagents = const [];
  List<DbNoteMaterial> _materials = const [];
  List<DbNoteReference> _references = const [];
  List<quill.EmbedBuilder> _buildEmbedBuilders(
    quill.QuillController controller,
  ) {
    final baseBuilders = kIsWeb
        ? FlutterQuillEmbeds.editorWebBuilders()
        : FlutterQuillEmbeds.editorBuilders();

    return baseBuilders.map<quill.EmbedBuilder>((builder) {
      if (builder.key == 'image') {
        return _SelectableImageEmbedBuilder(
          baseBuilder: builder,
          onTapImage: (imagePath) async {
            await _confirmDeleteImage(
              controller: controller,
              imagePath: imagePath,
            );
          },
        );
      }
      return builder;
    }).toList();
  }

  int? _findImageEmbedOffsetByPath(
    quill.QuillController controller,
    String imagePath,
  ) {
    final target = _normalizeImageRef(imagePath);
    final delta = controller.document.toDelta().toList();

    int offset = 0;

    for (final op in delta) {
      final data = op.data;

      if (data is String) {
        offset += data.length;
        continue;
      }

      if (data is Map && data['image'] is String) {
        final current = _normalizeImageRef(data['image'] as String);
        if (current == target) {
          return offset;
        }
        offset += 1;
        continue;
      }

      offset += 1;
    }

    return null;
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _saveIfNeeded(force: true);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _titleQuill.addListener(_onTitleChanged);
    _bodyQuill.addListener(_onBodyChanged);

    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();

    _titleQuill.removeListener(_onTitleChanged);
    _bodyQuill.removeListener(_onBodyChanged);

    _titleQuill.dispose();
    _bodyQuill.dispose();

    _titleFocus.dispose();
    _bodyFocus.dispose();

    _titleScroll.dispose();
    _bodyScroll.dispose();

    super.dispose();
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

    _suppressEditorListener = true;
    try {
      decodeDocOrPlainText(_titleQuill, noteAny?.title);
      decodeDocOrPlainText(_bodyQuill, noteAny?.body);
      _dirty = false;
      _lastSavedAt = null;
    } finally {
      _suppressEditorListener = false;
    }

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
    if (_suppressEditorListener || _noteIsDeleted) return;

    _enforceTitleOneLine();
    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  void _onBodyChanged() {
    if (_suppressEditorListener || _noteIsDeleted) return;

    final refs = extractImagePathsFromDoc(_bodyQuill)
        .map(_normalizeImageRef)
        .toSet();

    if (_selectedBodyImagePath != null &&
        !refs.contains(_normalizeImageRef(_selectedBodyImagePath!))) {
      if (mounted) {
        setState(() {
          _selectedBodyImagePath = null;
        });
      } else {
        _selectedBodyImagePath = null;
      }
    }

    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  void _markDirtyAndDebounceSave({required bool triggerRebuild}) {
    _dirty = true;

    if (triggerRebuild && mounted) {
      setState(() {});
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await _saveIfNeeded();
    });
  }

  Future<void> _saveIfNeeded({bool force = false}) async {
    if (_noteIsDeleted) return;
    if (_saving) return;
    if (!force && !_dirty) return;

    final titleJson = encodeDoc(_titleQuill);
    final bodyJson = encodeDoc(_bodyQuill);

    setState(() => _saving = true);
    try {
      await _db.updateNote(
        id: widget.noteId,
        title: titleJson,
        body: bodyJson,
      );

      _dirty = false;
      _lastSavedAt = DateTime.now();

      // 이미지 정리 검증 완료 전까지 비활성 유지
      await _deleteUnreferencedNoteImages();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _dirty = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          action: SnackBarAction(
            label: '재시도',
            onPressed: () {
              _saveIfNeeded(force: true);
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<Directory> _noteBaseImageDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'note_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _noteImageDir() async {
    final base = await _noteBaseImageDir();
    final dir = Directory(p.join(base.path, 'note_${widget.noteId}'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _formatSavedTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _noteImagePrefix() => 'img_';

  String? _selectedBodyImagePath;

  String _normalizeImageRef(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;

    if (t.startsWith('file://')) {
      try {
        return Uri.parse(t).toFilePath(windows: false);
      } catch (_) {
        return t;
      }
    }
    return t;
  }

  Future<bool> _isManagedNoteImagePath(String path) async {
    final dir = await _noteImageDir();
    final abs = p.normalize(path);
    final root = p.normalize(dir.path);

    if (!p.isWithin(root, abs)) return false;

    final fileName = p.basename(abs);
    return fileName.startsWith(_noteImagePrefix());
  }

  Future<Set<String>> _referencedImagesForThisNote() async {
    final used = <String>{};

    final refs = <String>{
      ...extractImagePathsFromDoc(_titleQuill),
      ...extractImagePathsFromDoc(_bodyQuill),
    }.map(_normalizeImageRef);

    final dir = await _noteImageDir();

    for (final r in refs) {
      if (r.isEmpty) continue;

      final abs = p.isAbsolute(r)
          ? p.normalize(r)
          : p.normalize(p.join(dir.path, r));

      if (p.isWithin(p.normalize(dir.path), abs)) {
        used.add(abs);
      }
    }

    return used;
  }

  Future<void> _deleteUnreferencedNoteImages() async {
    if (_cleanupRunning) return;
    _cleanupRunning = true;

    try {
      final used = await _referencedImagesForThisNote();
      final dir = await _noteImageDir();
      if (!await dir.exists()) return;

      final files = dir.listSync().whereType<File>().toList(growable: false);

      for (final f in files) {
        final abs = p.normalize(f.path);

        if (!await _isManagedNoteImagePath(abs)) continue;
        if (used.contains(abs)) continue;

        try {
          await f.delete();
        } catch (_) {}
      }
    } finally {
      _cleanupRunning = false;
    }
  }

  Future<void> _deleteAllNoteImages() async {
    final dir = await _noteImageDir();
    if (!await dir.exists()) return;

    try {
      await dir.delete(recursive: true);
    } catch (_) {
      try {
        final files = dir.listSync().whereType<File>().toList(growable: false);
        for (final f in files) {
          final abs = p.normalize(f.path);
          if (!await _isManagedNoteImagePath(abs)) continue;
          try {
            await f.delete();
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

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

  void _imageNotSupportedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 삽입은 모바일(Android/iOS)에서만 지원됩니다.')),
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
      await _saveIfNeeded(force: true);
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
      await _deleteAllNoteImages();
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

  String _plainTextForTitle(quill.QuillController c) {
    final t = c.document.toPlainText().replaceAll('\n', ' ').trim();
    return t.isEmpty ? '(제목 없음)' : t;
  }

  String _currentTitleForAppBar() => _plainTextForTitle(_titleQuill);

  void _enforceTitleOneLine() {
    final plain = _titleQuill.document.toPlainText();
    if (!plain.contains('\n')) return;

    final fixed = plain.replaceAll('\n', ' ').trimRight();

    _suppressEditorListener = true;
    try {
      _titleQuill.document = quill.Document()..insert(0, fixed);
      _titleQuill.updateSelection(
        TextSelection.collapsed(offset: fixed.length),
        quill.ChangeSource.local,
      );
    } finally {
      _suppressEditorListener = false;
    }
  }

  Widget _saveStatusChip(BuildContext context) {
    final theme = Theme.of(context);

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

    if (_noteIsDeleted) {
      return const SizedBox.shrink();
    }

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

    final savedLabel = _lastSavedAt == null
        ? '저장됨'
        : '${_formatSavedTime(_lastSavedAt!)} 저장됨';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        visualDensity: VisualDensity.compact,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 16),
            const SizedBox(width: 6),
            Text(savedLabel),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
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

    if (company != null && company.trim().isNotEmpty) {
      parts.add(company.trim());
    }
    if (cat != null && cat.trim().isNotEmpty) {
      parts.add('Cat: ${cat.trim()}');
    }
    if (lot != null && lot.trim().isNotEmpty) {
      parts.add('Lot: ${lot.trim()}');
    }
    if (memo != null && memo.trim().isNotEmpty) {
      parts.add(memo.trim());
    }

    return parts.join(' · ');
  }

  Widget _editorHeader({
    required String title,
    VoidCallback? onInsertImage,
    VoidCallback? onDeleteImage,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (onDeleteImage != null)
          IconButton(
            tooltip: '선택 이미지 삭제',
            onPressed: onDeleteImage,
            icon: const Icon(Icons.delete_outline),
          ),
        if (onInsertImage != null)
          IconButton(
            tooltip: '이미지 삽입',
            onPressed: onInsertImage,
            icon: const Icon(Icons.add_photo_alternate),
          ),
      ],
    );
  }
     
  Widget _buildQuillEditor({
    required quill.QuillController controller,
    required FocusNode focusNode,
    required ScrollController scrollController,
    required String placeholder,
    required double minHeight,
    required bool enabled,
  }) {
    controller.readOnly = !enabled;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: quill.QuillEditor(
        controller: controller,
        focusNode: focusNode,
        scrollController: scrollController,
        config: quill.QuillEditorConfig(
          placeholder: placeholder,
          expands: false,
          padding: EdgeInsets.zero,
          embedBuilders: _buildEmbedBuilders(controller),
        ),
      ),
    );
  }

  Future<void> _insertImageInto({
    required quill.QuillController controller,
    required FocusNode focusNode,
  }) async {
    if (!_imageInsertSupported) {
      _imageNotSupportedSnack();
      return;
    }
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    FocusScope.of(context).requestFocus(focusNode);
    await Future.delayed(const Duration(milliseconds: 10));

    final source = await _pickSourceSheet();
    if (source == null) return;

    final double? maxMb = await _askMaxSizeMb();
    if (maxMb == null) return;

    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final inputFile = File(picked.path);

    final outFile = await _compressToTargetMb(
      inputFile: inputFile,
      targetMb: maxMb,
    );

    final embedPath = _normalizeImageRef(outFile.path);
    final embed = quill.BlockEmbed.image(embedPath);

    final docLength = controller.document.length;
    final baseOffset = controller.selection.baseOffset;

    final index = (baseOffset >= 0 && baseOffset < docLength)
        ? baseOffset
        : max(0, docLength - 1);

    controller.replaceText(
      index,
      0,
      embed,
      TextSelection.collapsed(offset: index + 1),
    );

    if (controller == _bodyQuill) {
      setState(() {
        _selectedBodyImagePath = embedPath;
      });
    }

    _markDirtyAndDebounceSave(triggerRebuild: true);
    debugPrint('--- after image insert ---');
    debugPrint(jsonEncode(controller.document.toDelta().toJson()));
  }



  Future<void> _deleteSelectedBodyImage() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final selectedPath = _selectedBodyImagePath;
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 삭제할 이미지를 선택해 주세요.')),
      );
      return;
    }

    final imageOffset = _findImageEmbedOffsetByPath(_bodyQuill, selectedPath);
    if (imageOffset == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 이미지를 문서에서 찾지 못했습니다.')),
      );
      setState(() => _selectedBodyImagePath = null);
      return;
    }

    _bodyQuill.replaceText(
      imageOffset,
      1,
      '',
      TextSelection.collapsed(offset: max(0, imageOffset)),
    );

    setState(() => _selectedBodyImagePath = null);

    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  Future<void> _deleteImageByPath({
    required quill.QuillController controller,
    required String imagePath,
  }) async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final delta = controller.document.toDelta().toList();

    int offset = 0;
    int? targetOffset;

    for (final op in delta) {
      final data = op.data;

      if (data is String) {
        offset += data.length;
        continue;
      }

      if (data is Map && data['image'] is String) {
        final currentPath = _normalizeImageRef(data['image'] as String);
        final targetPath = _normalizeImageRef(imagePath);

        if (currentPath == targetPath) {
          targetOffset = offset;
          break;
        }

        offset += 1;
        continue;
      }

      offset += 1;
    }

    if (targetOffset == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 이미지를 찾지 못했습니다.')),
      );
      return;
    }

    controller.replaceText(
      targetOffset,
      1,
      '',
      TextSelection.collapsed(offset: max(0, targetOffset - 1)),
    );

    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  Future<void> _confirmDeleteImage({
    required quill.QuillController controller,
    required String imagePath,
  }) async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('이 이미지만 삭제할까요?'),
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

    if (ok == true) {
      await _deleteImageByPath(
        controller: controller,
        imagePath: imagePath,
      );
    }
  }

  Future<ImageSource?> _pickSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('이미지 폴더'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _askMaxSizeMb() async {
    final ctrl = TextEditingController(text: '1.0');

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미지 용량 제한'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '최대 MB (예: 1.0)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }

  Future<File> _compressToTargetMb({
    required File inputFile,
    required double targetMb,
  }) async {
    final targetBytes = (targetMb * 1024 * 1024).round();

    final inputBytes = await inputFile.readAsBytes();
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputFile;

    final dir = await _noteImageDir();
    final outPath = p.join(
      dir.path,
      '${_noteImagePrefix()}${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    if (inputBytes.length <= targetBytes) {
      final jpg = img.encodeJpg(decoded, quality: 95);
      final f = File(outPath);
      await f.writeAsBytes(jpg, flush: true);
      return f;
    }

    img.Image working = decoded;

    for (int resizeStep = 0; resizeStep < 10; resizeStep++) {
      final best = _bestJpegUnderBytes(working, targetBytes);
      if (best != null) {
        final f = File(outPath);
        await f.writeAsBytes(best, flush: true);
        return f;
      }

      final w = working.width;
      final h = working.height;

      if (w <= 320 || h <= 320) break;

      const scale = 0.88;
      final newW = max(320, (w * scale).round());
      final newH = max(320, (h * scale).round());

      working = img.copyResize(
        working,
        width: newW,
        height: newH,
        interpolation: img.Interpolation.average,
      );
    }

    final fallback = img.encodeJpg(working, quality: 20);
    final f = File(outPath);
    await f.writeAsBytes(fallback, flush: true);
    return f;
  }

  List<int>? _bestJpegUnderBytes(img.Image working, int targetBytes) {
    int lo = 5;
    int hi = 95;
    List<int>? best;

    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final jpg = img.encodeJpg(working, quality: mid);

      if (jpg.length <= targetBytes) {
        best = jpg;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    return best;
  }

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
          const SnackBar(
            content: Text('OCR 결과가 비어 있습니다. 더 선명한 이미지로 다시 시도해 주세요.'),
          ),
        );
      }
      return null;
    }

    return text;
  }

  Future<String> _extractTextWithMlKit(String imagePath) async {
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

  Future<void> _addReagent() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

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
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

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
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => _DoiEntryDialog(
        enableOcr: _ocrSupported,
        onRequestOcrText: _runOcrAndReturnText,
      ),
    );
    if (result == null) return;

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
    }
  }

  Future<void> _deleteReagent(String id) async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }
    await _db.noteItemsDao.deleteReagent(id);
    await _loadAll();
  }

  Future<void> _deleteMaterial(String id) async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }
    await _db.noteItemsDao.deleteMaterial(id);
    await _loadAll();
  }

  Future<void> _deleteReference(String id) async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }
    await _db.noteItemsDao.deleteReference(id);
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_noteLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope<bool>(
      canPop: !_saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        try {
          await _saveIfNeeded(force: true);
        } catch (_) {}
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentTitleForAppBar()),
          actions: [
            _saveStatusChip(context),
            TextButton.icon(
              onPressed: (_noteIsDeleted || _saving)
                  ? null
                  : () => _saveIfNeeded(force: true),
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
                      child: Text(
                        '이 노트는 삭제 상태입니다. 복원하면 제목/내용과 시약/재료/DOI를 다시 수정할 수 있습니다.',
                      ),
                    ),
                  ),
                ),
              _editorHeader(
                title: '연구제목',
              ),
              _buildQuillEditor(
                controller: _titleQuill,
                focusNode: _titleFocus,
                scrollController: _titleScroll,
                placeholder: '연구제목을 입력하세요',
                minHeight: 70,
                enabled: !_noteIsDeleted,
              ),
            
              const SizedBox(height: 12),
              _editorHeader(
                title: '연구내용',
                onDeleteImage: _deleteSelectedBodyImage,
                onInsertImage: () => _insertImageInto(
                  controller: _bodyQuill,
                  focusNode: _bodyFocus,
                ),
              ),

              _buildQuillEditor(
                controller: _bodyQuill,
                focusNode: _bodyFocus,
                scrollController: _bodyScroll,
                placeholder: '연구내용을 입력하세요',
                minHeight: 260,
                enabled: !_noteIsDeleted,
              ),
              const SizedBox(height: 16),
              const Divider(height: 32),
              if (_itemsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
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
      ),
    );
  }
}
