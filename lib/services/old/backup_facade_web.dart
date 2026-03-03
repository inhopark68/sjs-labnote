import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'backup_facade.dart';
import '../web_backup_service.dart.bak';

class _WebBackupFacade implements BackupFacade {
  @override
  Future<void> createAndExport(BuildContext context) async {
    final zip = await WebBackupService.createAttachmentsBackupZipBytes(
      appVersion: '1.0.0',
    );
    WebBackupService.downloadZipBytes(zip, fileName: 'labnote_backup.zip');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('백업 ZIP 다운로드가 시작되었습니다.')));
  }

  @override
  Future<void> pickAndRestore(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final Uint8List? bytes = res.files.single.bytes;
    if (bytes == null) return;

    await WebBackupService.restoreAttachmentsBackupZipBytes(bytes);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('복원 완료(웹 IndexedDB 첨부)')));
  }
}

BackupFacade createFacade() => _WebBackupFacade();
