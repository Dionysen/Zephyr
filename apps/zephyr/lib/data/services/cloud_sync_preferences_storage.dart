import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/cloud_sync.dart';

class CloudSyncPreferencesStorage {
  CloudSyncPreferencesStorage({
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  Future<File> _file() async {
    final root = await _supportDirectory();
    final dir = Directory(path.join(root.path, 'zephyr'));
    await dir.create(recursive: true);
    return File(path.join(dir.path, 'cloud_sync_preferences.json'));
  }

  Future<CloudSyncPreferences> load() async {
    final file = await _file();
    if (!await file.exists()) return CloudSyncPreferences.defaults;
    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return CloudSyncPreferences.fromJson(map);
    } on Object {
      return CloudSyncPreferences.defaults;
    }
  }

  Future<void> save(CloudSyncPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
  }
}
