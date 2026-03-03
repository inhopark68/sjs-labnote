import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'db/app_database_stub.dart' as stub;
import 'state/database_manager.dart';
import 'dao/note_dao.dart';
import 'services/attachment_storage.dart';
import 'services/image_compressor.dart';
import 'repositories/reagent_repository_drift.dart';
import 'repositories/cell_repository_drift.dart';
import 'repositories/equipment_repository_drift.dart';
import 'features/home/home_vm.dart';
import 'features/home/home_screen.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              DatabaseManager(stub.AppDatabase(stub.openConnection())),
        ),

        ProxyProvider<DatabaseManager, NoteDao>(
          update: (_, mgr, _) => NoteDao(mgr.db),
        ),

        // ✅ 웹/모바일 조건부 구현 사용
        Provider<AttachmentStorage>(create: (_) => createAttachmentStorage()),

        Provider(
          create: (_) => const ImageCompressor(maxSide: 2000, jpegQuality: 80),
        ),

        ProxyProvider<DatabaseManager, ReagentRepositoryDrift>(
          update: (_, mgr, _) => ReagentRepositoryDrift(mgr.db),
        ),
        ProxyProvider<DatabaseManager, CellRepositoryDrift>(
          update: (_, mgr, _) => CellRepositoryDrift(mgr.db),
        ),
        ProxyProvider<DatabaseManager, EquipmentRepositoryDrift>(
          update: (_, mgr, _) => EquipmentRepositoryDrift(mgr.db),
        ),

        // ✅ empty 제거: create에서도 db 주입
        ChangeNotifierProxyProvider<DatabaseManager, HomeVm>(
          create: (context) =>
              HomeVm(context.read<DatabaseManager>().db)..init(),
          update: (_, mgr, _) => HomeVm(mgr.db)..init(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}
