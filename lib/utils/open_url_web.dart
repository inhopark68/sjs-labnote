import 'dart:html' as html;

Future<void> openUrlExternal(String url) async {
  html.window.open(url, '_blank');
}