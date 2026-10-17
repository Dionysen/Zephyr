import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'zephyr_secure_storage.dart';

/// Minimal secure key-value API for WebDAV sessions and LLM API keys.
abstract class ZephyrKeyValueSecureStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements ZephyrKeyValueSecureStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? zephyrSecureStorage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

/// macOS debug runs are ad-hoc signed (`CODE_SIGN_IDENTITY = "-"`). Keychain
/// ACL is tied to the binary, so every rebuild can prompt for the login
/// keychain password. A local file in app support avoids that during `flutter
/// run` while release macOS builds still use the Keychain.
class MacOsDebugKeyValueSecureStore implements ZephyrKeyValueSecureStore {
  MacOsDebugKeyValueSecureStore();

  static const _fileName = 'zephyr_debug_secrets.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(path.join(dir.path, _fileName));
  }

  Future<Map<String, String>> _loadMap() async {
    final file = await _file();
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry('$key', value is String ? value : '$value'),
      );
    } on Object {
      return {};
    }
  }

  Future<void> _saveMap(Map<String, String> map) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map));
  }

  @override
  Future<String?> read({required String key}) async {
    final map = await _loadMap();
    return map[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    final map = await _loadMap();
    map[key] = value;
    await _saveMap(map);
  }

  @override
  Future<void> delete({required String key}) async {
    final map = await _loadMap();
    if (!map.containsKey(key)) return;
    map.remove(key);
    await _saveMap(map);
  }
}

bool get _useMacOsDebugSecretsFile {
  if (kReleaseMode || kIsWeb || !Platform.isMacOS) return false;
  // Keep widget tests on FlutterSecureStorage.setMockInitialValues.
  return Platform.environment['FLUTTER_TEST'] != 'true';
}

final ZephyrKeyValueSecureStore zephyrKeyValueSecureStore =
    _useMacOsDebugSecretsFile
    ? MacOsDebugKeyValueSecureStore()
    : FlutterSecureKeyValueStore();
