import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_vm.dart';
import 'features/notes/notes_page.dart';

import 'services/backup_service.dart';
import 'services/backup_service_impl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

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

        // BackupService는 AppDatabase에 의존하므로 ProxyProvider 하나만 두는 게 깔끔합니다.
        ProxyProvider<AppDatabase, BackupService>(
          update: (_, db, __) => BackupServiceImpl(db),
        ),

        ChangeNotifierProvider<HomeVm>(
          create: (ctx) => HomeVm(ctx.read<AppDatabase>()),
        ),
      ],
      child: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabNote',
      home: const HomeScreen(),
      routes: {
        '/notes': (_) => const NotesPage(),
      },
    );
  }
}