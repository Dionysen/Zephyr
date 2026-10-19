import 'dart:convert';

import '../../domain/models/cloud_sync.dart';
import 'zephyr_key_value_secure_store.dart';

/// Persists WebDAV credentials in platform secure storage.
class CloudAuthSecureStore {
  CloudAuthSecureStore({ZephyrKeyValueSecureStore? storage})
    : _storage = storage ?? zephyrKeyValueSecureStore;

  static const _sessionKey = 'zephyr.cloud.webdav.session';

  final ZephyrKeyValueSecureStore _storage;

  Future<CloudSyncSession?> loadSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CloudSyncSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> saveSession(CloudSyncSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
