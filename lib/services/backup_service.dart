<<<<<<< HEAD
import 'dart:typed_data';

abstract class BackupService {
  /// ✅ 백업 ZIP 바이트 생성
  Future<Uint8List> exportZip();

  /// ✅ 백업 ZIP 바이트로 복원 (전체 덮어쓰기)
  Future<void> restoreZip(Uint8List zipBytes);
}

/// 옵션(필요하면 확장)
class BackupOptions {
  const BackupOptions({this.includeDeleted = false});
  final bool includeDeleted;
}
=======
abstract class BackupService {
  Future<String> exportToJson();
  Future<void> importFromJson(String json);

  /// 내보내기(옵션 암호화)
  Future<void> exportBackup({String? password});

  /// 파일 선택 raw 텍스트 (웹/모바일 분기는 platform이 처리)
  Future<String?> pickRawBackupText();

  /// raw 텍스트 복원 (옵션 비밀번호)
  Future<void> importRawBackupText(String raw, {String? password});

  /// ✅ 제품형: 복원 전 자동 백업(PRE-RESTORE, 항상 암호화) 생성 후 복원
  Future<void> safeImportWithPreBackup({
    required String rawBackupText,
    required String preBackupPassword,
    String? importPassword,
  });
}
>>>>>>> c0d9cc10fb9f9d4d6e2435b93ad1afa17fb614f3
