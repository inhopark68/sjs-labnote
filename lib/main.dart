import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// -----------------------------
// 프로젝트 내부 모듈 import
// -----------------------------
import 'data/app_database.dart'; // Drift 기반 DB (NotesRepository 구현체)
import 'dao/note_dao.dart'; // 노트 관련 DAO(프로젝트에서 따로 쓰는 경우)
import 'features/home/home_screen.dart'; // 앱 시작 화면(현재는 NotesPage를 감싸는 홈)
import 'features/home/home_vm.dart'; // 홈 화면용 ViewModel(대시보드로 확장 시 사용)
import 'features/notes/notes_page.dart'; // 노트 목록 화면
import 'repositories/reagent_repository_drift.dart'; // 기타 도메인 repository (drift)
import 'services/attachment_storage.dart'; // 첨부파일 저장소 팩토리(createAttachmentStorage)
import 'services/backup_service.dart'; // 백업 서비스 인터페이스
import 'services/backup_service_impl.dart'; // 백업 서비스 구현체(암호화/플랫폼 I/O)
import 'services/image_compressor.dart'; // 이미지 압축 서비스
import 'viewmodels/app_settings.dart'; // 앱 설정(다크모드 등) 상태/저장
import 'viewmodels/notes_vm.dart'; // 노트 목록/검색/CRUD ViewModel

/// 앱 진입점
Future<void> main() async {
  // Flutter 엔진 초기화 (비동기 작업 전에 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 설정 로드 (예: 다크모드 on/off를 로컬에서 읽어옴)
  final appSettings = AppSettings();
  await appSettings.load();

  // Provider 트리 구성 후 앱 실행
  runApp(
    MultiProvider(
      providers: [
        // -----------------------------
        // DB Provider
        // -----------------------------
        // AppDatabase는 Drift DB이며, NotesRepository를 implements 하도록 구성되어 있음.
        // dispose에서 close()를 호출해 리소스 정리.
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),

        // -----------------------------
        // Settings Provider
        // -----------------------------
        // 이미 만들어둔 appSettings 인스턴스를 그대로 주입
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),

        // -----------------------------
        // Services Providers
        // -----------------------------
        // BackupService: 구현체(BackupServiceImpl)에 DB를 주입해서 생성
        Provider<BackupService>(
          create: (ctx) => BackupServiceImpl(ctx.read<AppDatabase>()),
        ),

        // NoteDao: DB를 주입해서 생성
        Provider<NoteDao>(
          create: (ctx) => NoteDao(ctx.read<AppDatabase>()),
        ),

        // AttachmentStorage: 플랫폼별 구현을 팩토리로 생성
        Provider<AttachmentStorage>(
          create: (_) => createAttachmentStorage(),
        ),

        // ImageCompressor: 이미지 처리 유틸 서비스
        Provider<ImageCompressor>(
          create: (_) => ImageCompressor(),
        ),

        // ReagentRepositoryDrift: 기타 도메인 repo (DB 주입)
        Provider<ReagentRepositoryDrift>(
          create: (ctx) => ReagentRepositoryDrift(ctx.read<AppDatabase>()),
        ),

        // -----------------------------
        // ViewModels Providers
        // -----------------------------
        // NotesVM: 노트 목록/검색/CRUD 담당
        // NotesVM은 NotesRepository를 받는데, AppDatabase가 이를 implements 함.
        ChangeNotifierProvider<NotesVM>(
          create: (ctx) => NotesVM(ctx.read<AppDatabase>()),
        ),

        // HomeVm: 홈(대시보드) 화면에서 사용할 VM
        // 현재 HomeScreen이 NotesPage를 반환하더라도, 추후 홈 확장 대비해 주입 유지 가능.
        ChangeNotifierProvider<HomeVm>(
          create: (ctx) => HomeVm(ctx.read<AppDatabase>())..init(),
        ),
      ],

      // 실제 위젯 트리 시작점
      child: const MyApp(),
    ),
  );
}

/// MaterialApp을 구성하는 최상위 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppSettings를 구독(watch)해서 설정 변경 시(MaterialApp 재빌드) 테마 반영
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabNote',

      // Material 3 사용 + 다크모드/라이트모드 설정 반영
      theme: ThemeData(
        useMaterial3: true,
        brightness: settings.darkMode ? Brightness.dark : Brightness.light,
      ),

      // -----------------------------
      // 첫 화면(Entry Screen)
      // -----------------------------
      // home: 앱이 시작되면 최초로 보여줄 화면
      // 현재 HomeScreen은 내부에서 NotesPage를 그대로 반환(홈=노트목록 UX)
      home: const HomeScreen(),

      // -----------------------------
      // 라우팅 테이블
      // -----------------------------
      // Navigator.pushNamed(context, '/notes') 하면 NotesPage로 이동
      // 현재는 home에서 이미 노트목록을 보여주지만,
      // 나중에 HomeScreen을 대시보드로 확장할 경우를 대비해 유지
      routes: {
        '/notes': (_) => const NotesPage(),
      },
    );
  }
}