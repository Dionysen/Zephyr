import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/cloud_sync.dart';

/// Persists WebDAV credentials in platform secure storage.
class CloudAuthSecureStore {
  CloudAuthSecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'zephyr.cloud.webdav.session';

  final FlutterSecureStorage _storage;

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
