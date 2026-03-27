import 'dart:io';

Future<String> savePdfBytes({
  required List<int> bytes,
  required String fileName,
}) async {
  final String normalizedFileName = _normalizeFileName(fileName);
  final List<Directory> candidateDirectories = <Directory>[
    if (Platform.isAndroid) Directory('/storage/emulated/0/Download'),
    if (Platform.isWindows && Platform.environment['USERPROFILE'] != null)
      Directory('${Platform.environment['USERPROFILE']}\\Downloads'),
    if ((Platform.isLinux || Platform.isMacOS) && Platform.environment['HOME'] != null)
      Directory('${Platform.environment['HOME']}/Downloads'),
    Directory.systemTemp,
  ];

  Object? lastError;

  for (final Directory directory in candidateDirectories) {
    try {
      if (!await directory.exists()) {
        continue;
      }

      final File file = File('${directory.path}${Platform.pathSeparator}$normalizedFileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error) {
      lastError = error;
    }
  }

  throw Exception(
    lastError == null
        ? 'Unable to save PDF file.'
        : 'Unable to save PDF file: $lastError',
  );
}

String _normalizeFileName(String fileName) {
  final String trimmed = fileName.trim();
  final String sanitized = trimmed
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  if (sanitized.isEmpty) {
    return 'ticket.pdf';
  }
  return sanitized.toLowerCase().endsWith('.pdf') ? sanitized : '$sanitized.pdf';
}
