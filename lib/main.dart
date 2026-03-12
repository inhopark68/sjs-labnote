import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'features/home/home_screen.dart';
import 'features/home/home_vm.dart';
import 'pages/note_detail_page.dart';
import 'viewmodels/app_settings.dart';

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
        ChangeNotifierProvider<AppSettings>(
          create: (_) => AppSettings(),
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
            home: const HomeScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/noteDetail') {
                final noteId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => NoteDetailPage(noteId: noteId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}