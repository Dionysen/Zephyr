import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/library_backup.dart';

class BackupPreferencesFileStorage {
  BackupPreferencesFileStorage({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  Future<File> _file() async {
    final root = await _supportDirectory();
    final dir = Directory(path.join(root.path, 'zephyr'));
    await dir.create(recursive: true);
    return File(path.join(dir.path, 'backup_preferences.json'));
  }

  Future<BackupPreferences> load() async {
    final file = await _file();
    if (!await file.exists()) return BackupPreferences.defaults;
    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final last = map['lastAutoBackupAt'];
      return BackupPreferences(
        autoBackupEnabled: map['autoBackupEnabled'] as bool? ?? true,
        lastAutoBackupAt: last is int
            ? DateTime.fromMillisecondsSinceEpoch(last)
            : null,
      );
    } on Object {
      return BackupPreferences.defaults;
    }
  }

  Future<void> save(BackupPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode({
        'autoBackupEnabled': preferences.autoBackupEnabled,
        if (preferences.lastAutoBackupAt != null)
          'lastAutoBackupAt':
              preferences.lastAutoBackupAt!.millisecondsSinceEpoch,
      }),
      flush: true,
    );
  }
}
