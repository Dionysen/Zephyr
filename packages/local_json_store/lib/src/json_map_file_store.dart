import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Reads and writes one JSON object beneath an injected directory.
///
/// The caller owns the directory choice and relative path. Missing files return
/// null; malformed JSON and I/O failures propagate to the caller.
class JsonMapFileStore {
  JsonMapFileStore({
    required this.directoryProvider,
    required this.relativePath,
    required this.invalidMessage,
  });

  final Future<Directory> Function() directoryProvider;
  final String relativePath;
  final String invalidMessage;

  Future<Map<String, Object?>?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) throw FormatException(invalidMessage);
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> write(Map<String, Object?> values) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(values), flush: true);
  }

  Future<File> _file() async {
    final root = await directoryProvider();
    return File(path.join(root.path, relativePath));
  }
}
