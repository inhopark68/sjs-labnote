import 'package:url_launcher/url_launcher.dart';

Future<void> openUrlExternal(String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (!ok) throw StateError('launchUrl returned false');
}