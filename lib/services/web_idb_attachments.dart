import 'dart:typed_data';
import 'package:idb_shim/idb_browser.dart';

class WebIdbAttachments {
  static const _dbName = 'labnote_db';
  static const _storeName = 'attachments';

  static final IdbFactory _factory = getIdbFactory()!;

  static Future<Database> _openDb() async {
    return _factory.open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = (e.target as Request).result;
        if (!db.objectStoreNames.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  static Future<void> putBytes({
    required String key,
    required Uint8List bytes,
    String mime = 'image/jpeg',
  }) async {
    final db = await _openDb();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);
    await store.put({'mime': mime, 'bytes': bytes}, key);
    await tx.completed;
    db.close();
  }

  static Future<({Uint8List bytes, String mime})?> getBytes(String key) async {
    final db = await _openDb();
    final tx = db.transaction(_storeName, idbModeReadOnly);
    final store = tx.objectStore(_storeName);

    final obj = await store.getObject(key);
    await tx.completed;
    db.close();

    if (obj == null) return null;
    final map = obj as Map;
    final mime = (map['mime'] as String?) ?? 'application/octet-stream';
    final bytes = map['bytes'] as Uint8List?;
    if (bytes == null) return null;
    return (bytes: bytes, mime: mime);
  }

  static Future<void> delete(String key) async {
    final db = await _openDb();
    final tx = db.transaction(_storeName, idbModeReadWrite);
    final store = tx.objectStore(_storeName);
    await store.delete(key);
    await tx.completed;
    db.close();
  }

  static Future<List<String>> keys() async {
    final db = await _openDb();
    final tx = db.transaction(_storeName, idbModeReadOnly);
    final store = tx.objectStore(_storeName);

    final result = <String>[];
    await store.openCursor(autoAdvance: true).listen((cursor) {
      final k = cursor.key;
      if (k is String) result.add(k);
    }).asFuture<void>();

    await tx.completed;
    db.close();
    return result;
  }
}
