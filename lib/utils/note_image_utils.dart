import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> noteBaseImageDir() async {
  final base = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(base.path, 'note_images'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<Directory> noteImageDir(int noteId) async {
  final base = await noteBaseImageDir();
  final dir = Directory(p.join(base.path, 'note_$noteId'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

String normalizeImageRef(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;

  if (t.startsWith('file://')) {
    try {
      return Uri.parse(t).toFilePath(windows: false);
    } catch (_) {
      return t;
    }
  }
  return t;
}

Future<bool> isManagedNoteImagePath({
  required int noteId,
  required String path,
  String filePrefix = 'img_',
}) async {
  final dir = await noteImageDir(noteId);
  final abs = p.normalize(path);
  final root = p.normalize(dir.path);

  if (!p.isWithin(root, abs)) return false;

  final fileName = p.basename(abs);
  return fileName.startsWith(filePrefix);
}

Future<Set<String>> referencedImagesForNote({
  required int noteId,
  required Iterable<String> refs,
}) async {
  final used = <String>{};
  final dir = await noteImageDir(noteId);

  for (final r0 in refs) {
    final r = normalizeImageRef(r0);
    if (r.isEmpty) continue;

    final abs = p.isAbsolute(r)
        ? p.normalize(r)
        : p.normalize(p.join(dir.path, r));

    if (p.isWithin(p.normalize(dir.path), abs)) {
      used.add(abs);
    }
  }

  return used;
}

Future<void> deleteUnreferencedNoteImages({
  required int noteId,
  required Iterable<String> refs,
  String filePrefix = 'img_',
}) async {
  final used = await referencedImagesForNote(
    noteId: noteId,
    refs: refs,
  );

  final dir = await noteImageDir(noteId);
  if (!await dir.exists()) return;

  final files = dir.listSync().whereType<File>().toList(growable: false);

  for (final f in files) {
    final abs = p.normalize(f.path);

    if (!await isManagedNoteImagePath(
      noteId: noteId,
      path: abs,
      filePrefix: filePrefix,
    )) {
      continue;
    }

    if (used.contains(abs)) continue;

    try {
      await f.delete();
    } catch (_) {}
  }
}

Future<void> deleteAllNoteImages(int noteId) async {
  final dir = await noteImageDir(noteId);
  if (!await dir.exists()) return;

  try {
    await dir.delete(recursive: true);
  } catch (_) {
    try {
      final files = dir.listSync().whereType<File>().toList(growable: false);
      for (final f in files) {
        try {
          await f.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}