import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Which device class owns a cloud settings artifact.
enum CloudSettingsPlatform {
  desktop,
  mobile;

  static CloudSettingsPlatform detect() {
    if (kIsWeb) return CloudSettingsPlatform.desktop;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS =>
        CloudSettingsPlatform.mobile,
      _ => CloudSettingsPlatform.desktop,
    };
  }

  /// Remote file under `Zephyr/` for this platform.
  String get cloudFileName => switch (this) {
    CloudSettingsPlatform.desktop => 'settings-desktop.json',
    CloudSettingsPlatform.mobile => 'settings-mobile.json',
  };

  /// Pre-split shared name. Desktop may read once for migration; mobile never.
  static const legacyCloudFileName = 'settings.json';
}

/// Packs / restores Zephyr app-support JSON prefs for cloud sync.
///
/// Kept separate from PureWriter `.pwb` so Room snapshots stay compatible.
/// Desktop and mobile upload different remote files so layout / chrome prefs
/// do not cross-contaminate.
class CloudSettingsBundle {
  CloudSettingsBundle({
    Future<Directory> Function()? supportDirectory,
    CloudSettingsPlatform? platform,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       platform = platform ?? CloudSettingsPlatform.detect();

  final Future<Directory> Function() _supportDirectory;
  final CloudSettingsPlatform platform;

  static const schema = 1;

  /// Pref files included in cloud settings (Nutstore credentials excluded).
  static const relativePaths = <String>[
    'zephyr/editor-preferences.json',
    'zephyr/theme-tokens.json',
    'zephyr/quick-toolbar.json',
    'zephyr/keyboard-shortcuts.json',
    'zephyr/backup_preferences.json',
    'zephyr/workspace-layout.json',
    'zephyr/window-frame.json',
    'zephyr/llm_preferences.json',
  ];

  String get cloudFileName => platform.cloudFileName;

  /// Desktop may fall back to the pre-split remote file; mobile must not.
  String? get legacyCloudFileNameFallback =>
      platform == CloudSettingsPlatform.desktop
      ? CloudSettingsPlatform.legacyCloudFileName
      : null;

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
      'platform': platform.name,
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
