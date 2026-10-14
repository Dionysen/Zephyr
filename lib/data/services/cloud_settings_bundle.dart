import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Packs / restores Zephyr app-support JSON prefs for cloud sync.
///
/// Kept separate from PureWriter `.pwb` so Room snapshots stay compatible.
/// Relative paths are under the application support directory.
class CloudSettingsBundle {
  CloudSettingsBundle({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  static const schema = 1;
  static const cloudFileName = 'settings.json';

  /// Pref files included in cloud settings (Nutstore credentials excluded).
  static const relativePaths = <String>[
    'zephyr/editor-preferences.json',
    'zephyr/theme-tokens.json',
    'zephyr/quick-toolbar.json',
    'zephyr/keyboard-shortcuts.json',
    'zephyr/backup_preferences.json',
    'zephyr/workspace-layout.json',
    'zephyr/window-frame.json',
  ];

  /// Build a JSON document of existing preference files.
  Future<Map<String, Object?>> exportJson() async {
    final root = await _supportDirectory();
    final files = <String, String>{};
    for (final relative in relativePaths) {
      final file = File(path.join(root.path, relative));
      if (!await file.exists()) continue;
      files[relative] = await file.readAsString();
    }
    return {
      'schema': schema,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'files': files,
    };
  }

  /// Write [document] files into application support (overwrites present keys).
  Future<int> importJson(Map<String, dynamic> document) async {
    final files = document['files'];
    if (files is! Map) return 0;
    final root = await _supportDirectory();
    var written = 0;
    for (final entry in files.entries) {
      final relative = entry.key.toString().replaceAll('\\', '/');
      if (!relativePaths.contains(relative)) continue;
      final raw = entry.value;
      if (raw is! String) continue;
      // Reject path escape (keep posix-style keys from [relativePaths]).
      final parts = relative.split('/');
      if (parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
        continue;
      }
      final file = File(path.joinAll([root.path, ...parts]));
      await file.parent.create(recursive: true);
      await file.writeAsString(raw, flush: true);
      written++;
    }
    return written;
  }

  Future<List<int>> exportBytes() async {
    final json = await exportJson();
    return utf8.encode(jsonEncode(json));
  }

  Future<int> importBytes(List<int> bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid cloud settings bundle.');
    }
    return importJson(decoded);
  }
}
