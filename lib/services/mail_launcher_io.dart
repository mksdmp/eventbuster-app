import 'package:flutter/services.dart';

const MethodChannel _mailLauncherChannel = MethodChannel('eventbuster/mail_launcher');

Future<bool> launchSupportEmail(String email) async {
  final String trimmedEmail = email.trim();
  if (trimmedEmail.isEmpty) {
    return false;
  }

  try {
    final bool? didLaunch = await _mailLauncherChannel.invokeMethod<bool>(
      'launchMailto',
      <String, String>{'email': trimmedEmail},
    );
    return didLaunch == true;
  } catch (_) {
    return false;
  }
}
