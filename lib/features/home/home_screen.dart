import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:labnote/features/home/home_vm.dart';
import 'package:labnote/features/notes/note_detail_page.dart';
import 'package:labnote/features/scan/scan_result.dart';
import 'package:labnote/features/scan/scan_result_dialog.dart';
import 'package:labnote/features/trash/trash_screen.dart';
import 'package:labnote/services/image_scan_service.dart';

import 'package:labnote/features/reagents/reagent_draft.dart';
import 'package:labnote/features/reagents/add_reagent_draft_dialog.dart';

ReagentDraft buildReagentDraftFromScan(ScanFromImageResult result) {
  String name = '스캔 시약';

  if ((result.parsed.company?.isNotEmpty ?? false) &&
      (result.parsed.catalogNumber?.isNotEmpty ?? false)) {
    name = '${result.parsed.company} ${result.parsed.catalogNumber}';
  } else if ((result.parsed.catalogNumber?.isNotEmpty ?? false)) {
    name = '시약 ${result.parsed.catalogNumber}';
  } else if (result.text.trim().isNotEmpty) {
    final firstLine = result.text.trim().split('\n').first.trim();
    if (firstLine.isNotEmpty) {
      name = firstLine.length > 40 ? firstLine.substring(0, 40) : firstLine;
    }
  }

  return ReagentDraft(
    name: name,
    company: result.parsed.company,
    catalogNumber: result.parsed.catalogNumber,
    lotNumber: result.parsed.lotNumber,
    memo: result.text.trim().isEmpty ? null : result.text.trim(),
  );
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
    } catch (_) {
      // Quill JSON 파싱 실패 시 일반 문자열로 처리
    }
  }

  return raw.replaceAll('\n', ' ').trim();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final _imageScanService = ImageScanService();

  bool _inited = false;
  HomeVm? _vm;

  String _buildScanNoteTitle(ScanFromImageResult result) {
    String title;

    if ((result.parsed.company?.isNotEmpty ?? false) &&
        (result.parsed.catalogNumber?.isNotEmpty ?? false)) {
      title = '${result.parsed.company} ${result.parsed.catalogNumber}';
    } else if ((result.parsed.catalogNumber?.isNotEmpty ?? false)) {
      title = '시약 ${result.parsed.catalogNumber}';
    } else if (result.codes.isNotEmpty) {
      final first = result.codes.first;
      final value = (first.displayValue ?? first.rawValue ?? '').trim();
      title = value.isNotEmpty ? '스캔: $value' : '스캔 가져오기';
    } else {
      final text = result.text.trim();
      if (text.isNotEmpty) {
        final firstLine = text.split('\n').first.trim();
        title = firstLine.isNotEmpty ? firstLine : '스캔 가져오기';
      } else {
        title = '스캔 가져오기';
      }
    }

    return title.length > 40 ? title.substring(0, 40) : title;
  }

  ReagentDraft _buildReagentDraftFromDialogResult(
    ScanFromImageResult result,
    String combinedText,
  ) {
    final base = buildReagentDraftFromScan(result);
    return ReagentDraft(
      name: base.name,
      company: base.company,
      catalogNumber: base.catalogNumber,
      lotNumber: base.lotNumber,
      memo: combinedText.trim().isEmpty ? null : combinedText.trim(),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _vm = context.read<HomeVm>();
      _scrollCtrl.addListener(_onScroll);
    });
  }

  void _onScroll() {
    final vm = _vm;
    if (vm == null) return;
    if (!_scrollCtrl.hasClients) return;
    if (vm.loadingMore || !vm.hasMore) return;

    final threshold = _scrollCtrl.position.maxScrollExtent - 200;
    if (_scrollCtrl.position.pixels > threshold) {
      vm.loadMore();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    Future.microtask(() => context.read<HomeVm>().init());
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndScan() async {
    try {
      final messenger = ScaffoldMessenger.of(context);

      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null) return;

      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('이미지 분석 중...')),
        );

      final result = await _imageScanService.scanImage(file.path);

      if (!mounted) return;
      messenger.clearSnackBars();

      if (result.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('인식된 QR/OCR 정보가 없습니다.')),
        );
        return;
      }

      final dialogResult = await showDialog<ScanDialogResult>(
        context: context,
        builder: (_) => ScanResultDialog(result: result),
      );

      if (dialogResult == null) return;

      if (dialogResult.action == ScanDialogAction.insertNote) {
        final vm = context.read<HomeVm>();
        final title = _buildScanNoteTitle(result);

        final noteId = await vm.createNoteFromScannedText(
          title: title,
          body: dialogResult.combinedText.trim(),
        );

        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteDetailPage(noteId: noteId),
          ),
        );

        if (!mounted) return;
        await vm.refresh();
        return;
      }

      if (dialogResult.action == ScanDialogAction.addReagent) {
        final draft = _buildReagentDraftFromDialogResult(
          result,
          dialogResult.combinedText,
        );

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AddReagentDialog(
            initialDraft: draft,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('OCR scan failed: $e');
      debugPrint('$st');

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('이미지 분석 실패: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeVm>();
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LabNote'),
        actions: [
          IconButton(
            tooltip: '사진에서 QR/OCR 읽기',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _pickImageAndScan,
          ),
          IconButton(
            tooltip: vm.searchVisible ? '검색 닫기' : '검색',
            icon: Icon(vm.searchVisible ? Icons.close : Icons.search),
            onPressed: vm.toggleSearch,
          ),
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: vm.loading ? null : vm.refresh,
          ),
          IconButton(
            tooltip: '휴지통',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrashScreen()),
              );

              if (!mounted) return;
              await context.read<HomeVm>().refresh();
            },
          ),
        ],
        bottom: vm.searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '검색(제목/본문)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: vm.setQuery,
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(vm, messenger),
      floatingActionButton: FloatingActionButton(
        tooltip: '새 노트',
        child: const Icon(Icons.add),
        onPressed: () async {
          try {
            final id = await vm.insertEmptyAndReturnId();
            debugPrint('new note id=$id (${id.runtimeType})');

            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailPage(noteId: id),
              ),
            );

            if (!mounted) return;
            await vm.refresh();
          } catch (e, st) {
            debugPrint('new note failed: $e\n$st');

            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(content: Text('새 노트 열기 실패: $e')),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: (vm.hasMore && !vm.loading && vm.items.isNotEmpty)
          ? const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '스크롤하면 더 불러옵니다',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    HomeVm vm,
    ScaffoldMessengerState messenger,
  ) {
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.items.isEmpty) {
      return const Center(child: Text('표시할 노트가 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: vm.items.length + (vm.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= vm.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = vm.items[index];
          final plainTitle = quillStoredTextToPlain(item.title);
          final plainBody = quillStoredTextToPlain(item.bodyPreview);

          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('삭제할까요?'),
                  content: const Text('노트가 삭제됨으로 표시됩니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );
              return ok == true;
            },
            onDismissed: (_) async {
              try {
                await vm.deleteNoteOptimistic(item.id);

                if (!mounted) return;

                messenger
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text('삭제됨'),
                      action: SnackBarAction(
                        label: '되돌리기',
                        onPressed: () async {
                          try {
                            await vm.restoreDeletedNote(item.id);
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('복구 실패: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('삭제 실패: $e')),
                );
              }
            },
            child: ListTile(
              leading: item.isPinned ? const Icon(Icons.push_pin) : null,
              title: Text(
                plainTitle.isEmpty ? '(제목 없음)' : plainTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                plainBody,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteDetailPage(noteId: item.id),
                  ),
                );

                if (changed == true && mounted) {
                  await vm.refresh();
                }
              },
            ),
          );
        },
      ),
    );
  }
}