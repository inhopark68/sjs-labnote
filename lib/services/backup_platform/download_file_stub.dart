Future<void> downloadBytes({
  required List<int> bytes,
  required String filename,
  required String mime,
}) async {
  // non-web: no-op (모바일/데스크탑은 추후 share/save 붙이면 됨)
}