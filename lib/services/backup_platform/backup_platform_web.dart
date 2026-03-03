import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

class BackupPlatform {
  static Future<void> exportJson(
    String json, {
    String fileBaseName = 'labnote-backup',
    String? fileNameOverride, // ✅ 추가
  }) async {
    final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = fileNameOverride ?? '$fileBaseName-$ts.json';

    final bytes = utf8.encode(json);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final a = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';

    html.document.body!.append(a);
    a.click();
    a.remove();

    html.Url.revokeObjectUrl(url);
  }

  static Future<String?> pickJsonText() {
    final completer = Completer<String?>();

    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json'
      ..multiple = false;

    input.onChange.listen((_) {
      final file = (input.files?.isNotEmpty ?? false)
          ? input.files!.first
          : null;

      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.readAsText(file);

      reader.onLoad.listen((_) {
        completer.complete(reader.result as String?);
      });

      reader.onError.listen((_) {
        completer.completeError(StateError('파일 읽기 실패'));
      });
    });

    input.click();
    return completer.future;
  }
}
