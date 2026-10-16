import '../../domain/models/llm_settings.dart';
import '../../domain/repositories/llm_settings_repository.dart';
import '../services/llm_api_key_store.dart';
import '../services/llm_preferences_storage.dart';

class FileLlmSettingsRepository implements LlmSettingsRepository {
  FileLlmSettingsRepository({
    LlmPreferencesStorage? preferencesStorage,
    LlmApiKeyStore? apiKeyStore,
  }) : _preferencesStorage = preferencesStorage ?? LlmPreferencesStorage(),
       _apiKeyStore = apiKeyStore ?? LlmApiKeyStore();

  final LlmPreferencesStorage _preferencesStorage;
  final LlmApiKeyStore _apiKeyStore;

  @override
  Future<LlmPreferences> loadPreferences() => _preferencesStorage.load();

  @override
  Future<void> savePreferences(LlmPreferences preferences) =>
      _preferencesStorage.save(preferences);

  @override
  Future<String?> loadApiKey(LlmProviderKind provider) =>
      _apiKeyStore.read(provider);

  @override
  Future<void> saveApiKey(LlmProviderKind provider, String apiKey) =>
      _apiKeyStore.write(provider, apiKey);
}
