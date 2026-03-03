import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupPlatform {
  static Future<void> exportJson(
    String json, {
    String fileBaseName = 'labnote-backup',
    String? fileNameOverride, // ✅ 추가
  }) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = fileNameOverride ?? '$fileBaseName-$ts.json';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(json, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'LabNote 백업',
      text: 'LabNote 백업 파일입니다.',
    );
  }

  static Future<String?> pickJsonText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final f = result.files.single;

    if (f.path != null) return await File(f.path!).readAsString();
    if (f.bytes != null) return utf8.decode(f.bytes!);

    throw StateError('선택한 파일을 읽을 수 없습니다.');
  }
}
