import '../data/app_database.dart';

abstract class ReagentRepository {
  Future<String> createOrUpdateFromOcr({
    required String name,
    String? vendor,
    String? catalogNo,
    String? lot,
    DateTime? expDate,
    String? labelPhotoPath,
    String? ocrText,
    String? labelSha256,
  });
}

class ReagentRepositoryDrift implements ReagentRepository {
  final AppDatabase data;
  ReagentRepositoryDrift(this.data);

  @override
  Future<String> createOrUpdateFromOcr({
    required String name,
    String? vendor,
    String? catalogNo,
    String? lot,
    DateTime? expDate,
    String? labelPhotoPath,
    String? ocrText,
    String? labelSha256,
  }) async {
    // TODO: replace with real drift implementation (see conversation)
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
