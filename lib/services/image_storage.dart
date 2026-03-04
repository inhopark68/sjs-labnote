import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorage {
  Future<File> saveImage(File image) async {
    final dir = await getApplicationDocumentsDirectory();

    final imagesDir = Directory('${dir.path}/images');

    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final saved = await image.copy(
      path.join(imagesDir.path, '$fileName.jpg'),
    );

    return saved;
  }
}