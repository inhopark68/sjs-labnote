import 'backup_service.dart';

class IoBackupService implements BackupService {
  final BackupOptions opt;
  IoBackupService(this.opt);

  @override
  Future<BackupResult> createBackupZip({required String appVersion}) async {
    throw UnimplementedError('Implement IO createBackupZip');
  }

  @override
  Future<RestoreResult> restoreBackupZip({
    required String zipPath,
    required Future<void> Function() beforeCloseDb,
    required Future<void> Function() afterReopenDb,
    bool verifyChecksums = true,
  }) async {
    throw UnimplementedError('Implement IO restoreBackupZip');
  }
}
