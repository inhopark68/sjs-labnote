import 'backup_service.dart';
import 'old/backup_service_io_impl.dart';

BackupService createBackupServiceImpl(BackupOptions opt) =>
    IoBackupService(opt);
