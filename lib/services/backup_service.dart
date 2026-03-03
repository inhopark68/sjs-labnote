abstract class BackupService {
  Future<String> exportToJson();
  Future<void> importFromJson(String json);

  /// 내보내기(옵션 암호화)
  Future<void> exportBackup({String? password});

  /// 파일 선택 raw 텍스트 (웹/모바일 분기는 platform이 처리)
  Future<String?> pickRawBackupText();

  /// raw 텍스트 복원 (옵션 비밀번호)
  Future<void> importRawBackupText(String raw, {String? password});

  /// ✅ 복원 전 자동 백업(PRE-RESTORE) 생성 후 복원
  Future<void> safeImportWithPreBackup({
    required String rawBackupText,
    required String preBackupPassword,
    String? importPassword,
  });
}