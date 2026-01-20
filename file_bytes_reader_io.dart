import 'dart:io';

Future<List<int>?> readFileBytesFromPath(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    return bytes;
  } catch (_) {
    return null;
  }
}
