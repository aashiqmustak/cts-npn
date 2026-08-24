import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> saveFile({
  required Uint8List bytes,
  required String fileName,
  String mimeType = 'application/pdf',
}) async {
  await Printing.sharePdf(bytes: bytes, filename: fileName);
}
