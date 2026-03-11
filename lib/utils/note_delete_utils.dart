import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/app_database.dart';

Future<void> hardDeleteNoteWithAssets({
  required AppDatabase db,
  required int noteId,
}) async {
  try {
    final baseDir = await getApplicationDocumentsDirectory();
    final noteImagesDir =
        Directory(p.join(baseDir.path, 'note_images', 'note_$noteId'));

    if (await noteImagesDir.exists()) {
      await noteImagesDir.delete(recursive: true);
    }
  } catch (_) {
    // 이미지 삭제 실패해도 DB 삭제는 계속 진행
  }

  await db.hardDeleteNote(noteId);
}note_delete_utils.dart