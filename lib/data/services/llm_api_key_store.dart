import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/llm_settings.dart';

/// API keys per [LlmProviderKind], stored in platform secure storage.
class LlmApiKeyStore {
  LlmApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _keyFor(LlmProviderKind provider) => 'zephyr.llm.api_key.${provider.name}';

  Future<String?> read(LlmProviderKind provider) async {
    final value = await _storage.read(key: _keyFor(provider));
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> write(LlmProviderKind provider, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await delete(provider);
      return;
    }
    await _storage.write(key: _keyFor(provider), value: trimmed);
  }

  Future<void> delete(LlmProviderKind provider) async {
    await _storage.delete(key: _keyFor(provider));
  }
}
