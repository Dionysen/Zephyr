import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/llm_settings.dart';

class LlmPreferencesStorage {
  LlmPreferencesStorage({
    Future<Directory> Function()? supportDirectory,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  Future<File> _file() async {
    final root = await _supportDirectory();
    final dir = Directory(path.join(root.path, 'zephyr'));
    await dir.create(recursive: true);
    return File(path.join(dir.path, 'llm_preferences.json'));
  }

  Future<LlmPreferences> load() async {
    final file = await _file();
    if (!await file.exists()) return LlmPreferences.defaults;
    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return LlmPreferences.fromJson(map);
    } on Object {
      return LlmPreferences.defaults;
    }
  }

  Future<void> save(LlmPreferences preferences) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(preferences.toJson()), flush: true);
  }
}
