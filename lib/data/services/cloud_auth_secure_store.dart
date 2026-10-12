import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/cloud_sync.dart';

/// Persists Aliyun Drive tokens and optional developer App credentials.
class CloudAuthSecureStore {
  CloudAuthSecureStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'zephyr.cloud.aliyun.session';
  static const _clientIdKey = 'zephyr.cloud.aliyun.client_id';
  static const _clientSecretKey = 'zephyr.cloud.aliyun.client_secret';

  final FlutterSecureStorage _storage;

  Future<CloudSyncSession?> loadSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CloudSyncSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
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

  Future<AliyunDriveAppCredentials?> loadStoredAppCredentials() async {
    final id = await _storage.read(key: _clientIdKey);
    final secret = await _storage.read(key: _clientSecretKey);
    if (id == null ||
        secret == null ||
        id.isEmpty ||
        secret.isEmpty) {
      return null;
    }
    return AliyunDriveAppCredentials(clientId: id, clientSecret: secret);
  }

  Future<void> saveStoredAppCredentials(AliyunDriveAppCredentials credentials) async {
    await _storage.write(key: _clientIdKey, value: credentials.clientId);
    await _storage.write(key: _clientSecretKey, value: credentials.clientSecret);
  }

  Future<void> clearStoredAppCredentials() async {
    await _storage.delete(key: _clientIdKey);
    await _storage.delete(key: _clientSecretKey);
  }
}
