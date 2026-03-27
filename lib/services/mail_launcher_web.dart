// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> launchSupportEmail(String email) async {
  final String trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    return false;
  }

  html.window.open('mailto:$trimmedEmail', '_self');
  return true;
}
