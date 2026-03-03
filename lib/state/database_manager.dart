import 'package:flutter/foundation.dart';
import '../db/app_database.dart';

/// DB 인스턴스를 교체 가능한 형태로 감싸는 매니저.
/// 복원(restore) 후 새 DB로 갈아끼우면 UI/Repo가 즉시 새 DB를 사용합니다.
class DatabaseManager extends ChangeNotifier {
  stub.AppDatabase _db;
  DatabaseManager(this._db);

  stub.AppDatabase get db => _db;

  Future<void> replaceDb(stub.AppDatabase newDb) async {
    _db = newDb;
    notifyListeners();
  }
}
