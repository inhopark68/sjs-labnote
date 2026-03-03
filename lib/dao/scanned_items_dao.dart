import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_db.dart';

class ScannedItemsDao extends DatabaseAccessor<AppDb>
    with _$ScannedItemsDaoMixin {
  ScannedItemsDao(super.db);

  Future<int> insertItem({
    required String kind,
    required String rawScanValue,
    String title = '',
    String? subtitle,
    String? identifier,
    String? sourceUrl,
    String? rawText,
    Map<String, dynamic>? payload,
  }) {
    return into(db.scannedItems).insert(
      ScannedItemsCompanion.insert(
        kind: kind,
        rawScanValue: rawScanValue,
        title: Value(title),
        subtitle: Value(subtitle),
        identifier: Value(identifier),
        sourceUrl: Value(sourceUrl),
        rawText: Value(rawText),
        payloadJson: Value(payload == null ? null : jsonEncode(payload)),
      ),
    );
  }

  Stream<List<ScannedItem>> watchLatest({int limit = 50}) {
    return (select(db.scannedItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }
}
// 팁: 중복 방지를 하고 싶으면 kind+identifier에 UNIQUE를 걸고 
//insertOnConflictUpdate로 upsert하면 됩니다.