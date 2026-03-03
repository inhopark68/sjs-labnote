// Future<void> openUrlExternal(String url) async {
//   throw UnsupportedError('openUrlExternal not implemented');
// }

//  open_url.dart를 conditional import로 교체
export 'open_url_io.dart'
  if (dart.library.html) 'open_url_web.dart';