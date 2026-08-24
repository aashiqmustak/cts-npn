import 'dart:typed_data';
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

abstract class FileDownloader {
  static Future<void> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/pdf',
  }) async {
    await saveFile(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }
}
