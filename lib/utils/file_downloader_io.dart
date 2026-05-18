import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveFileBytes(Uint8List bytes, String filename) async {
  Directory? downloads;
  try {
    downloads = await getDownloadsDirectory();
  } catch (_) {
    downloads = null;
  }

  downloads ??= await getApplicationDocumentsDirectory();
  final file = File('${downloads.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
