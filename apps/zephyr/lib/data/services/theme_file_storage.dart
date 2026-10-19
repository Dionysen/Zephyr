import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Low-level app-support-file access for global UI preferences.
class ThemeFileStorage {
  ThemeFileStorage({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;

  Future<Map<String, Object?>?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) throw const FormatException('Invalid theme settings.');
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> write(Map<String, Object?> values) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(values), flush: true);
  }

  Future<File> _file() async {
    final root = await _directoryProvider();
    return File(path.join(root.path, 'zephyr', 'theme-tokens.json'));
  }
}
