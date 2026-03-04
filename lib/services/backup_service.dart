import 'dart:typed_data';

abstract class BackupService {
  Future<Uint8List> exportBackup({String? password});

  Future<String?> pickRawBackupText();

  Future<void> safeImportWithPreBackup({
    required String rawBackupText,
    required String preBackupPassword,
    String? importPassword,
  });
}