import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/app_database.dart';
import '../state/database_manager.dart';
import 'backup_service.dart';
import 'android_download_exporter.dart';
import 'backup_platform/backup_picker.dart';
import 'backup_facade.dart.bak';

class _IoBackupFacade implements BackupFacade {
  BackupService _svc() =>
      createBackupService(const BackupOptions(appNameFolder: 'LabNote'));
  // 만약 BackupOptions가 const가 아니라면 위 줄을 아래로 바꾸세요:
  // BackupService _svc() => createBackupService(BackupOptions(appNameFolder: 'LabNote'));

  @override
  Future<void> createAndExport(BuildContext context) async {
    final svc = _svc();
    final res = await svc.createBackupZip(appVersion: '1.0.0');

    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidDownloadExporter().exportZipToDownloads(
        zipPath: res.zipPath,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloads에 백업 저장됨')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('백업 생성: ${res.zipPath}')));
    }
  }

  @override
  Future<void> pickAndRestore(BuildContext context) async {
    final zipPath = await BackupPicker().pickZipToLocalPath();
    if (zipPath == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('복원'),
        content: const Text('현재 데이터가 교체됩니다. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복원'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final mgr = context.read<DatabaseManager>();
    final svc = _svc();

    await svc.restoreBackupZip(
      zipPath: zipPath,
      beforeCloseDb: () async => mgr.db.close(),
      afterReopenDb: () async =>
          mgr.replaceDb(stub.AppDatabase(stub.openConnection())),
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('복원 완료(즉시 반영)')));
  }
}

BackupFacade createFacade() => _IoBackupFacade();
