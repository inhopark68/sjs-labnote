import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:image_picker/image_picker.dart';

// DB / util / 분리된 위젯들
import '../../data/app_database.dart';
import '../../utils/image_utils.dart';
import '../../utils/note_delete_utils.dart';
import '../../utils/note_image_utils.dart';
import '../../utils/ocr_utils.dart';
import '../../utils/quill_doc_utils.dart';
import '../../widgets/doi_entry_dialog.dart';
import '../../widgets/note_body_section.dart';
import '../../widgets/note_date_card.dart';
import '../../widgets/note_item_dialog.dart';
import '../../widgets/note_materials_section.dart';
import '../../widgets/note_reagents_section.dart';
import '../../widgets/note_references_section.dart';
import '../../widgets/note_title_section.dart';

/// 노트 상세 / 편집 페이지
/// - 제목/본문 Quill 편집
/// - 자동 저장
/// - 이미지 삽입/삭제
/// - OCR 기반 시약/재료/DOI 추가
/// - 휴지통 이동 / 복원 / 완전 삭제
class NoteDetailPage extends StatefulWidget {
  final int noteId;

  const NoteDetailPage({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

/// Quill 이미지 embed를 감싸서
/// 이미지 탭 시 선택 상태를 바꿀 수 있게 하는 builder
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
  /// Provider로 주입된 DB 접근자
  AppDatabase get _db => context.read<AppDatabase>();

  /// 제목 / 본문 Quill controller
  final quill.QuillController _titleQuill = quill.QuillController.basic();
  final quill.QuillController _bodyQuill = quill.QuillController.basic();

  /// 포커스/스크롤 제어
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();

  final ScrollController _titleScroll = ScrollController();
  final ScrollController _bodyScroll = ScrollController();

  /// 이미지 picker
  final ImagePicker _picker = ImagePicker();

  /// 자동 저장 debounce timer
  Timer? _debounce;

  /// 페이지 상태
  bool _noteLoading = true;
  bool _itemsLoading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _noteIsDeleted = false;

  /// Quill document를 코드로 바꿀 때 listener가 다시 반응하지 않게 막는 플래그
  bool _suppressEditorListener = false;

  /// 마지막 저장 시각 / 선택된 노트 날짜
  DateTime? _lastSavedAt;
  DateTime? _selectedNoteDate;

  /// 현재 노트 domain 모델
  Note? _note;

  /// 본문에서 현재 선택된 이미지 경로
  String? _selectedBodyImagePath;

  /// 부가 항목 목록
  List<DbNoteReagent> _reagents = const [];
  List<DbNoteMaterial> _materials = const [];
  List<DbNoteReference> _references = const [];

  /// 모바일에서만 OCR / 이미지 삽입 허용
  bool get _ocrSupported => !kIsWeb;
  bool get _imageInsertSupported => !kIsWeb;

  @override
  void initState() {
    super.initState();

    // 앱 lifecycle 감지 등록
    WidgetsBinding.instance.addObserver(this);

    // 제목/본문 변경 listener 등록
    _titleQuill.addListener(_onTitleChanged);
    _bodyQuill.addListener(_onBodyChanged);

    // 첫 진입 시 데이터 로드
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    // 앱이 백그라운드로 가기 직전 마지막 저장
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _debounce?.cancel();
      _saveIfNeeded(force: true);
    }
  }

  /// Quill editor용 embed builder 구성
  /// - image embed는 탭하면 선택되도록 래핑
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
            if (!mounted) return;

            setState(() {
              if (controller == _bodyQuill) {
                _selectedBodyImagePath = normalizeImageRef(imagePath);
              }
            });
          },
        );
      }
      return builder;
    }).toList();
  }

  /// 문서 delta를 순회해서 특정 이미지 embed가 있는 offset을 찾음
  int? _findImageEmbedOffsetByPath(
    quill.QuillController controller,
    String imagePath,
  ) {
    final target = normalizeImageRef(imagePath);
    final delta = controller.document.toDelta().toList();

    int offset = 0;

    for (final op in delta) {
      final data = op.data;

      if (data is String) {
        offset += data.length;
        continue;
      }

      if (data is Map && data['image'] is String) {
        final current = normalizeImageRef(data['image'] as String);
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

  /// 노트 + 시약/재료/DOI를 한 번에 로드
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
    _selectedNoteDate = noteAny?.noteDate;

    // DB의 저장 문자열(JSON 또는 plain text)을 Quill document로 복원
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

  /// 제목 변경 시
  /// - 한 줄 강제
  /// - dirty 처리
  /// - autosave debounce 시작
  void _onTitleChanged() {
    if (_suppressEditorListener || _noteIsDeleted) return;

    _enforceTitleOneLine();
    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  /// 본문 변경 시
  /// - 선택 이미지가 실제 문서에서 사라졌는지 확인
  /// - dirty 처리
  /// - autosave debounce 시작
  void _onBodyChanged() {
    if (_suppressEditorListener || _noteIsDeleted) return;

    final refs = extractImagePathsFromDoc(_bodyQuill)
        .map(normalizeImageRef)
        .toSet();

    if (_selectedBodyImagePath != null &&
        !refs.contains(normalizeImageRef(_selectedBodyImagePath!))) {
      if (mounted) {
        setState(() => _selectedBodyImagePath = null);
      } else {
        _selectedBodyImagePath = null;
      }
    }

    _markDirtyAndDebounceSave(triggerRebuild: false);
  }

  /// dirty 상태로 바꾸고 autosave 타이머 시작
  void _markDirtyAndDebounceSave({required bool triggerRebuild}) {
    _dirty = true;

    if (triggerRebuild && mounted) {
      setState(() {});
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      await _saveIfNeeded();
    });
  }

  /// 필요 시 저장
  /// - 제목/본문을 Delta JSON 문자열로 저장
  /// - 저장 후 미참조 이미지 파일 정리
  Future<void> _saveIfNeeded({bool force = false}) async {
    if (_noteIsDeleted) return;
    if (_saving) return;
    if (!force && !_dirty) return;

    final titleJson = encodeDoc(_titleQuill);
    final bodyJson = encodeDoc(_bodyQuill);

    if (mounted) {
      setState(() => _saving = true);
    } else {
      _saving = true;
    }

    try {
      await _db.updateNote(
        id: widget.noteId,
        title: titleJson,
        body: bodyJson,
      );

      _dirty = false;
      _lastSavedAt = DateTime.now();

      // 현재 문서에서 참조하지 않는 로컬 이미지 파일 정리
      await deleteUnreferencedNoteImages(
        noteId: widget.noteId,
        refs: {
          ...extractImagePathsFromDoc(_titleQuill),
          ...extractImagePathsFromDoc(_bodyQuill),
        },
        filePrefix: _noteImagePrefix(),
      );

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
      } else {
        _saving = false;
      }
    }
  }

  /// 노트별 관리 이미지 파일 prefix
  String _noteImagePrefix() => 'img_';

  /// 부가 항목용 간단한 문자열 ID 생성
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

  /// 공통 확인 다이얼로그
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

  /// soft delete
  Future<void> _moveToTrash() async {
    final ok = await _confirmDialog(
      title: '휴지통으로 이동',
      message: '이 노트를 휴지통으로 이동할까요?\n(완전 삭제가 아니며, 복원할 수 있습니다.)',
      okText: '이동',
    );
    if (!ok) return;

    try {
      _debounce?.cancel();
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

  /// 삭제 상태에서 복원
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

  /// 이미지 파일 + 관련 DB 레코드까지 포함한 완전 삭제
  Future<void> _confirmHardDelete() async {
    final ok = await _confirmDialog(
      title: '완전 삭제',
      message:
          '이 노트를 완전히 삭제할까요?\n노트에 연결된 시약/재료/DOI 기록도 함께 삭제되며, 복구할 수 없습니다.',
      okText: '완전 삭제',
    );
    if (!ok) return;

    try {
      _debounce?.cancel();
      await hardDeleteNoteWithAssets(
        db: _db,
        noteId: widget.noteId,
      );

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

  /// AppBar 제목용 plain text
  String _plainTextForTitle(quill.QuillController c) {
    final t = c.document.toPlainText().replaceAll('\n', ' ').trim();
    return t.isEmpty ? '(제목 없음)' : t;
  }

  String _currentTitleForAppBar() => _plainTextForTitle(_titleQuill);

  /// 제목 editor는 한 줄만 허용
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

  /// 저장 상태 표시 chip
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

  String _formatSavedTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// 이미지 소스 선택 bottom sheet
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

  /// 이미지 삽입 전 최대 용량(MB) 입력
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

  /// 이미지 삽입
  /// - 사진 선택
  /// - 압축
  /// - 로컬 note_images 폴더 저장
  /// - Quill 본문에 image embed 삽입
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

    final maxMb = await _askMaxSizeMb();
    if (maxMb == null) return;

    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final inputFile = File(picked.path);
    final dir = await noteImageDir(widget.noteId);

    final outFile = await compressImageToTargetMb(
      inputFile: inputFile,
      targetMb: maxMb,
      outputDir: dir,
      filePrefix: _noteImagePrefix(),
    );

    final embedPath = normalizeImageRef(outFile.path);
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
      setState(() => _selectedBodyImagePath = embedPath);
    }

    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  /// 현재 선택된 본문 이미지 삭제
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

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('선택한 이미지를 삭제할까요?'),
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

    if (ok != true) return;

    _bodyQuill.replaceText(
      imageOffset,
      1,
      '',
      TextSelection.collapsed(offset: max(0, imageOffset)),
    );

    setState(() => _selectedBodyImagePath = null);
    _markDirtyAndDebounceSave(triggerRebuild: true);
  }

  /// OCR 실행
  /// - 사진 선택
  /// - ML Kit 텍스트 추출
  /// - 공백/줄바꿈 정규화
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

    final raw = await extractTextWithMlKit(picked.path);
    final text = normalizeOcrText(raw);

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

  /// 노트 날짜 선택
  Future<void> _pickNoteDate() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final now = DateTime.now();
    final initial = _selectedNoteDate ?? _note?.noteDate ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    await _db.updateNoteDate(widget.noteId, picked);

    if (!mounted) return;
    setState(() {
      _selectedNoteDate = picked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('노트 날짜를 저장했습니다.')),
    );
  }

  /// 노트 날짜 제거
  Future<void> _clearNoteDate() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    await _db.updateNoteDate(widget.noteId, null);

    if (!mounted) return;
    setState(() {
      _selectedNoteDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('노트 날짜를 제거했습니다.')),
    );
  }

  /// 시약 추가
  Future<void> _addReagent() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final input = await showDialog<ItemEntryInput?>(
      context: context,
      builder: (_) => ItemEntryDialog(
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

  /// 재료 추가
  Future<void> _addMaterial() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final input = await showDialog<ItemEntryInput?>(
      context: context,
      builder: (_) => ItemEntryDialog(
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

  /// DOI reference 추가
  Future<void> _addReference() async {
    if (_noteIsDeleted) {
      _blockedSnack();
      return;
    }

    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => DoiEntryDialog(
        enableOcr: _ocrSupported,
        onRequestOcrText: _runOcrAndReturnText,
      ),
    );
    if (result == null) return;

    if (result is DoiEntryInput) {
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

    if (result is List<DoiEntryInput>) {
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
          _debounce?.cancel();
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
              // 삭제 상태 안내
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

              // 노트 날짜
              NoteDateCard(
                noteDate: _selectedNoteDate,
                onPickDate: _pickNoteDate,
                onClearDate: _selectedNoteDate != null ? _clearNoteDate : null,
              ),
              const SizedBox(height: 8),

              // 제목 섹션
              NoteTitleSection(
                controller: _titleQuill,
                focusNode: _titleFocus,
                scrollController: _titleScroll,
                enabled: !_noteIsDeleted,
              ),
              const SizedBox(height: 12),

              // 본문 섹션
              NoteBodySection(
                controller: _bodyQuill,
                focusNode: _bodyFocus,
                scrollController: _bodyScroll,
                enabled: !_noteIsDeleted,
                embedBuilders: _buildEmbedBuilders(_bodyQuill),
                onInsertImage: () => _insertImageInto(
                  controller: _bodyQuill,
                  focusNode: _bodyFocus,
                ),
                onDeleteImage: _selectedBodyImagePath == null
                    ? null
                    : _deleteSelectedBodyImage,
              ),

              const SizedBox(height: 16),
              const Divider(height: 32),

              // 시약/재료/DOI 영역 로딩
              if (_itemsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // 시약
                NoteReagentsSection(
                  reagents: _reagents,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted ? _blockedSnack : _addReagent,
                  onDelete: _deleteReagent,
                ),

                // 재료
                NoteMaterialsSection(
                  materials: _materials,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted ? _blockedSnack : _addMaterial,
                  onDelete: _deleteMaterial,
                ),

                // DOI reference
                NoteReferencesSection(
                  references: _references,
                  noteIsDeleted: _noteIsDeleted,
                  onAdd: _noteIsDeleted ? _blockedSnack : _addReference,
                  onDelete: _deleteReference,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}