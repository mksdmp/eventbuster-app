import 'package:flutter/services.dart';

const MethodChannel _mapLauncherChannel = MethodChannel('eventbuster/map_launcher');

Future<bool> launchMapSearchUrl(String url) async {
  final String trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) {
    return false;
  }

  try {
    final bool? didLaunch = await _mapLauncherChannel.invokeMethod<bool>(
      'openUrl',
      <String, String>{'url': trimmedUrl},
    );
    return didLaunch == true;
  } catch (_) {
    return false;
  }
}
