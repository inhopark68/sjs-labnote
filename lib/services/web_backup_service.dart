import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:archive/archive.dart';

import 'web_idb_attachments.dart'; // ✅ 반드시 필요

class WebBackupService {
  /// facade_web.dart가 호출하는 이름 (정식)
  static Future<Uint8List> createAttachmentsBackupZipBytes({
    String appName = 'LabNote',
    String appVersion = '1.0.0',
  }) async {
    final keys = await WebIdbAttachments.keys();
    final archive = Archive();

    final manifest = <String, dynamic>{
      'app': appName,
      'version': appVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'attachmentsCount': keys.length,
      'format': 1,
    };

    archive.addFile(
      ArchiveFile('manifest.json', 0, utf8.encode(jsonEncode(manifest))),
    );
    archive.addFile(
      ArchiveFile(
        'attachments/index.json',
        0,
        utf8.encode(jsonEncode({'keys': keys})),
      ),
    );

    for (final key in keys) {
      final data = await WebIdbAttachments.getBytes(key);
      if (data == null) continue;

      final safe = key.replaceAll('/', '_');
      archive.addFile(
        ArchiveFile('attachments/$safe', data.bytes.length, data.bytes),
      );
    }

    final zipped = ZipEncoder().encode(archive) ?? <int>[];
    return Uint8List.fromList(zipped);
  }

  static Future<void> restoreAttachmentsBackupZipBytes(
    Uint8List zipBytes,
  ) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final index = archive.files.firstWhere(
      (f) => f.name == 'attachments/index.json',
      orElse: () => throw StateError('attachments/index.json not found'),
    );

    final indexJson = utf8.decode(index.content as List<int>);
    final keys = (jsonDecode(indexJson)['keys'] as List).cast<String>();

    for (final key in keys) {
      final safe = key.replaceAll('/', '_');
      final entryName = 'attachments/$safe';

      final file = archive.files
          .where((f) => f.name == entryName)
          .cast<ArchiveFile?>()
          .firstWhere((x) => x != null, orElse: () => null);

      if (file == null) continue;

      final bytes = Uint8List.fromList(file.content as List<int>);
      await WebIdbAttachments.putBytes(
        key: key,
        bytes: bytes,
        mime: 'image/jpeg',
      );
    }
  }

  static void downloadZipBytes(
    Uint8List zipBytes, {
    String fileName = 'labnote_backup.zip',
  }) {
    final blob = html.Blob([zipBytes], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final a = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  }
}
