// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> launchMapSearchUrl(String url) async {
  final String trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    return false;
  }

  html.window.open(trimmedUrl, '_blank');
  return true;
}
