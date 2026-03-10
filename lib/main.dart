import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

// -----------------------------
// 프로젝트 내부 모듈 import
// -----------------------------
import 'data/app_database.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_vm.dart';
import 'features/notes/notes_page.dart';

import 'services/backup_service.dart';
import 'services/backup_service_impl.dart';

import 'viewmodels/app_settings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// 앱 전체 DI(Provider) + MaterialApp 구성
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),

        ChangeNotifierProvider<AppSettings>(
          create: (_) => AppSettings(),
        ),

        Provider<BackupService>(
          create: (ctx) => BackupServiceImpl(ctx.read<AppDatabase>()),
        ),

        ChangeNotifierProvider<HomeVm>(
          create: (ctx) => HomeVm(ctx.read<AppDatabase>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<AppSettings>();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LabNote',
            theme: ThemeData(
              useMaterial3: true,
              brightness:
                  settings.darkMode ? Brightness.dark : Brightness.light,
            ),
            localizationsDelegates: const [
              ...FlutterQuillLocalizations.localizationsDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: FlutterQuillLocalizations.supportedLocales,
            home: HomeScreen(),
            routes: {
              '/notes': (_) => const NotesPage(),
            },
          );
        },
      ),
    );
  }
}