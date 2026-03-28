Future<String> savePdfBytes({
  required List<int> bytes,
  required String fileName,
}) async {
  throw UnsupportedError('PDF saving is not supported on this platform.');
}

Future<String> downloadPdf({
  required String fileName,
  List<int>? bytes,
  Uri? url,
  Map<String, String>? headers,
}) async {
  if (bytes != null) {
    return savePdfBytes(
      bytes: bytes,
      fileName: fileName,
    );
  }
  throw UnsupportedError('PDF downloading is not supported on this platform.');
}
