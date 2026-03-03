import 'package:flutter/widgets.dart';


abstract class BackupFacade {
  Future<void> createAndExport(BuildContext context);
  Future<void> pickAndRestore(BuildContext context);
}

BackupFacade createBackupFacade() => createFacade();

/// 기본 구현(안전장치)
/// 실제로는 조건부 import로 연결된 backup_facade_web.dart 또는 backup_facade_io.dart의
/// createFacade()가 호출됩니다.
BackupFacade createFacade() {
  throw UnimplementedError(
    'createFacade() is not linked. Check conditional imports.',
  );
}
