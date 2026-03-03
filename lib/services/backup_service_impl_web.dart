import 'backup_service.dart';

BackupService createBackupServiceImpl(BackupOptions opt) => _WebBackupService();

class _WebBackupService implements BackupService {
  @override
  Future<BackupResult> createBackupZip({required String appVersion}) {
    throw UnsupportedError('Web backup not implemented');
  }

  @override
  Future<RestoreResult> restoreBackupZip({
    required String zipPath,
    required Future<void> Function() beforeCloseDb,
    required Future<void> Function() afterReopenDb,
    bool verifyChecksums = true,
  }) {
    throw UnsupportedError('Web restore not implemented');
  }
}
