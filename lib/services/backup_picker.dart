import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupPicker {
  Future<String?> pickZipToLocalPath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;

    if (f.path != null && f.path!.isNotEmpty) return f.path!;

    final bytes = f.bytes;
    if (bytes == null) return null;

    final temp = await getTemporaryDirectory();
    final name = f.name.isNotEmpty ? f.name : 'selected_backup.zip';
    final outPath = p.join(temp.path, 'restore_$name');
    await File(outPath).writeAsBytes(bytes, flush: true);
    return outPath;
  }
}
