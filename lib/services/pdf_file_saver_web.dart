// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String> savePdfBytes({
  required List<int> bytes,
  required String fileName,
}) async {
  final String normalizedFileName = _normalizeFileName(fileName);
  final html.Blob blob = html.Blob(<dynamic>[bytes], 'application/pdf');
  final String url = html.Url.createObjectUrlFromBlob(blob);

  try {
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..download = normalizedFileName
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }

  return normalizedFileName;
}

Future<String> downloadPdf({
  required String fileName,
  List<int>? bytes,
  Uri? url,
  Map<String, String>? headers,
}) async {
  if (bytes == null) {
    throw ArgumentError('PDF bytes are required on this platform.');
  }
  return savePdfBytes(
    bytes: bytes,
    fileName: fileName,
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
