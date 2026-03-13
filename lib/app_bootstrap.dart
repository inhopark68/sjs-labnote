import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/database/app_database.dart';
import 'features/home/home_vm.dart';
import 'features/home/home_screen.dart';
import 'features/figures/figures_vm.dart';
import 'services/attachment_storage.dart';
import 'services/image_compressor.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),

        Provider<AttachmentStorage>(
          create: (_) => createAttachmentStorage(),
        ),

        Provider<ImageCompressor>(
          create: (_) => const ImageCompressor(
            maxSide: 2000,
            jpegQuality: 80,
          ),
        ),

        ChangeNotifierProvider<HomeVm>(
          create: (context) => HomeVm(
            context.read<AppDatabase>(),
          )..init(),
        ),

        ChangeNotifierProvider<FiguresVm>(
          create: (context) => FiguresVm(
            context.read<AppDatabase>(),
          ),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}