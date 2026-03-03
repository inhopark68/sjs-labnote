import 'dart:io';
import 'package:media_store_plus/media_store_plus.dart';

class AndroidDownloadExporter {
  final MediaStore _mediaStore = MediaStore();

  Future<String?> exportZipToDownloads({required String zipPath}) async {
    if (!Platform.isAndroid) return null;
    final info = await _mediaStore.saveFile(
      tempFilePath: zipPath,
      dirType: DirType.download,
      dirName: DirType.download.defaults,
    );
    return info?.uri.toString();
  }
}
