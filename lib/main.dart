import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ✅ 기존 프로젝트 것들
import 'data/app_database.dart';
import 'pages/note_edit_page.dart';
import 'services/backup_service.dart';
import 'services/backup_service_impl.dart';
import 'viewmodels/app_settings.dart';
import 'viewmodels/notes_vm.dart';

// ✅ NoteSheet/Home에서 필요한 것들
import 'dao/note_dao.dart';
import 'services/attachment_storage.dart'; // createAttachmentStorage()
import 'services/image_compressor.dart';
import 'repositories/reagent_repository_drift.dart';

// ✅ 새 홈(인덱스) 화면 연결
import 'features/home/home_screen.dart';
import 'features/home/home_vm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appSettings = AppSettings();
  await appSettings.load();

  runApp(
    MultiProvider(
      providers: [
<<<<<<< HEAD
        Provider<AppDatabase>(
          create: (_) => AppDatabase(), // ✅ Drift DB는 내부에서 open
          dispose: (_, db) {
            db.close(); // ignore: discarded_futures
          },
        ),

=======
        // ---- DB ----
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),

        // ---- Settings ----
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),

        // ---- Services ----
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
        Provider<BackupService>(
          create: (ctx) => BackupServiceImpl(ctx.read<AppDatabase>()),
        ),

<<<<<<< HEAD
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
=======
        Provider<NoteDao>(create: (ctx) => NoteDao(ctx.read<AppDatabase>())),

        // ✅ 플랫폼별 storage 구현체 생성 팩토리
        Provider<AttachmentStorage>(create: (_) => createAttachmentStorage()),

        Provider<ImageCompressor>(create: (_) => ImageCompressor()),

        Provider<ReagentRepositoryDrift>(
          create: (ctx) => ReagentRepositoryDrift(ctx.read<AppDatabase>()),
        ),

        // ---- Existing notes VM (기존 화면 유지용) ----
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
        ChangeNotifierProvider<NotesVM>(
          create: (ctx) => NotesVM(ctx.read<AppDatabase>()),
        ),

        // ---- HomeScreen VM (DI 주입) ----
        ChangeNotifierProvider<HomeVm>(
          create: (ctx) => HomeVm(ctx.read<AppDatabase>())..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabNote',
      theme: ThemeData(
        useMaterial3: true,
        brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      ),

      // ✅ 인덱스(첫 화면): HomeScreen
      home: const HomeScreen(),

      // ✅ 기존 NotesPage도 유지
      routes: {'/notes': (_) => const NotesPage()},
    );
  }
}

<<<<<<< HEAD
class NotesPage extends StatelessWidget {
=======
// ----------------------------------------------------------------------
// 아래는 “기존 NotesPage” 그대로
// ----------------------------------------------------------------------

class NotesPage extends StatefulWidget {
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late final TextEditingController _searchCtrl;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runWithTopLoading({
    required Future<void> Function() job,
    required String successMsg,
    required String failPrefix,
  }) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    try {
      await job();
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMsg)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failPrefix: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _askPasswordForExport() async {
    final pw1 = TextEditingController();
    final pw2 = TextEditingController();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('백업 암호화'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('비밀번호를 입력하면 백업이 AES로 암호화됩니다.\n(비워두면 평문 백업)'),
              const SizedBox(height: 12),
              TextField(
                controller: pw1,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: '비밀번호(선택)',
                  suffixIcon: IconButton(
                    tooltip: obscure ? '비밀번호 보기' : '비밀번호 숨기기',
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
              TextField(
                controller: pw2,
                obscureText: obscure,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return null;

    final a = pw1.text.trim();
    final b = pw2.text.trim();

    if (a.isEmpty && b.isEmpty) return '';

    if (a.length < 4) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호는 4자 이상을 권장합니다.')));
      return null;
    }

    if (a != b) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')));
      return null;
    }

    return a;
  }

  Future<String?> _askPasswordForImport() async {
    final pw = TextEditingController();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('비밀번호 입력'),
          content: TextField(
            controller: pw,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: '백업 비밀번호',
              suffixIcon: IconButton(
                tooltip: obscure ? '비밀번호 보기' : '비밀번호 숨기기',
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setLocal(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return null;
    return pw.text.trim();
  }

  Future<void> _exportBackupUx() async {
    final password = await _askPasswordForExport();
    if (password == null) return;

    await _runWithTopLoading(
      job: () => context.read<BackupService>().exportBackup(
        password: password.isEmpty ? null : password,
      ),
      successMsg: '백업 내보내기 완료',
      failPrefix: '백업 내보내기 실패',
    );
  }

  Future<void> _importBackupUx() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('백업을 불러올까요?'),
        content: const Text(
          '복원 전에 현재 데이터를 1회 자동 백업(PRE-RESTORE)으로 저장합니다.\n'
          '그 다음 현재 노트가 백업 내용으로 "전체 교체"됩니다.\n'
          '계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('계속'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _runWithTopLoading(
      job: () async {
        final svc = context.read<BackupService>();

        final raw = await svc.pickRawBackupText();
        if (raw == null) return;

        bool isEncrypted = false;
        try {
          final decoded = jsonDecode(raw);
          isEncrypted =
              decoded is Map<String, dynamic> && decoded['encrypted'] == true;
        } catch (_) {
          throw StateError('백업 파일 형식이 올바르지 않습니다.');
        }

        String? importPw;
        if (isEncrypted) {
          importPw = await _askPasswordForImport();
          if (importPw == null || importPw.isEmpty) {
            throw StateError('암호화된 백업입니다. 비밀번호 입력이 필요합니다.');
          }
        }

        String preBackupPw = importPw ?? '';
        if (preBackupPw.isEmpty) {
          final p = await _askPasswordForExport();
          if (p == null || p.isEmpty) {
            throw StateError('복원 전 자동 백업은 안전을 위해 비밀번호가 필요합니다.');
          }
          preBackupPw = p;
        }

        await svc.safeImportWithPreBackup(
          rawBackupText: raw,
          preBackupPassword: preBackupPw,
          importPassword: importPw,
        );

        await context.read<NotesVM>().refresh();
      },
      successMsg: '백업 복원 완료 (PRE-RESTORE 자동 백업 생성됨)',
      failPrefix: '백업 복원 실패',
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesVM>();
    final settings = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            tooltip: '새로고침',
<<<<<<< HEAD
            onPressed: vm.isLoading ? null : () => context.read<NotesVM>().refresh(),
=======
            onPressed: _isBusy ? null : () => context.read<NotesVM>().refresh(),
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '다크모드 토글',
            onPressed: _isBusy
                ? null
                : () => context.read<AppSettings>().setDarkMode(
                    !settings.darkMode,
                  ),
            icon: Icon(settings.darkMode ? Icons.dark_mode : Icons.light_mode),
          ),
          IconButton(
            tooltip: '백업 내보내기',
            icon: const Icon(Icons.ios_share),
            onPressed: _isBusy ? null : _exportBackupUx,
          ),
          IconButton(
            tooltip: '백업 가져오기',
            icon: const Icon(Icons.upload_file),
            onPressed: _isBusy ? null : _importBackupUx,
          ),
          IconButton(
            tooltip: '새 노트',
<<<<<<< HEAD
            onPressed: () async {
              final result =
                  await Navigator.of(context).push<(String title, String body)>(
                MaterialPageRoute(
                  builder: (_) => const NoteEditPage(titleText: '새 노트'),
                ),
              );

              if (result != null) {
                final (title, body) = result;
                await context.read<NotesVM>().addNote(title: title, body: body);
              }
            },
=======
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
            icon: const Icon(Icons.add),
            onPressed: _isBusy
                ? null
                : () async {
                    final result = await Navigator.of(context)
                        .push<(String title, String body)>(
                          MaterialPageRoute(
                            builder: (_) =>
                                const NoteEditPage(titleText: '새 노트'),
                          ),
                        );

                    if (result != null) {
                      final (title, body) = result;
                      try {
                        await context.read<NotesVM>().addNote(
                          title: title,
                          body: body,
                        );

                        final count = await context
                            .read<NotesVM>()
                            .debugCountAll();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('저장 완료 / DB count=$count')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
                      }
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
<<<<<<< HEAD
=======
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: _isBusy
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '검색 (제목/내용)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => context.read<NotesVM>().setQuery(v),
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (vm.items.isEmpty
                      ? const Center(child: Text('노트가 없습니다'))
                      : ListView.separated(
                          itemCount: vm.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = vm.items[index];

<<<<<<< HEAD
                          return ListTile(
                            title: Text(item.title.isEmpty ? '(제목 없음)' : item.title),
                            subtitle: Text(item.bodyPreview),
                            trailing: IconButton(
                              tooltip: item.isPinned ? '고정 해제' : '상단 고정',
                              onPressed: () async {
                                await context.read<NotesVM>().togglePin(item.id);
                              },
                              icon: Icon(item.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined),
                            ),
                            onTap: () async {
                              // ✅ 원문 로드
                              final detail =
                                  await context.read<NotesVM>().getNote(item.id);

                              final result = await Navigator.of(context)
                                  .push<(String title, String body)>(
                                MaterialPageRoute(
                                  builder: (_) => NoteEditPage(
                                    titleText: '노트 수정',
                                    initialTitle: detail.title,
                                    initialBody: detail.body,
                                  ),
                                ),
                              );

                              if (result != null) {
                                final (title, body) = result;
                                await context.read<NotesVM>().updateNote(
                                      id: item.id,
                                      title: title,
                                      body: body,
                                    );
                              }
                            },
                            onLongPress: () {
                              final id = item.id;

                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('삭제할까요?'),
                                  content: Text(
                                    item.title.isEmpty ? '(제목 없음)' : item.title,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await context.read<NotesVM>().deleteNoteById(id);
=======
                            return ListTile(
                              title: Text(
                                item.title.isEmpty ? '(제목 없음)' : item.title,
                              ),
                              subtitle: Text(item.bodyPreview),
                              trailing: IconButton(
                                tooltip: item.isPinned ? '고정 해제' : '상단 고정',
                                icon: Icon(
                                  item.isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                ),
                                onPressed: _isBusy
                                    ? null
                                    : () async {
                                        try {
                                          await context
                                              .read<NotesVM>()
                                              .togglePin(item.id);
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('핀 변경 실패: $e'),
                                            ),
                                          );
                                        }
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
                                      },
                              ),
                              onTap: _isBusy
                                  ? null
                                  : () async {
                                      final result = await Navigator.of(context)
                                          .push<(String title, String body)>(
                                            MaterialPageRoute(
                                              builder: (_) => NoteEditPage(
                                                titleText: '노트 수정',
                                                initialTitle: item.title,
                                                initialBody: item.body,
                                              ),
                                            ),
                                          );

                                      if (result != null) {
                                        final (title, body) = result;
                                        try {
                                          await context
                                              .read<NotesVM>()
                                              .updateNote(
                                                id: item.id,
                                                title: title,
                                                body: body,
                                              );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('수정 완료'),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('수정 실패: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              onLongPress: _isBusy
                                  ? null
                                  : () {
                                      final rootContext = context;
                                      final id = item.id;

                                      showDialog(
                                        context: rootContext,
                                        builder: (_) => AlertDialog(
                                          title: const Text('삭제할까요?'),
                                          content: Text(
                                            item.title.isEmpty
                                                ? '(제목 없음)'
                                                : item.title,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(rootContext),
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                try {
                                                  await rootContext
                                                      .read<NotesVM>()
                                                      .deleteNoteById(id);
                                                  if (!mounted) return;

                                                  Navigator.pop(rootContext);
                                                  ScaffoldMessenger.of(
                                                    rootContext,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('삭제 완료'),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(
                                                    rootContext,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '삭제 실패: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text('삭제'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                            );
                          },
                        )),
          ),
        ],
      ),
    );
  }
}
