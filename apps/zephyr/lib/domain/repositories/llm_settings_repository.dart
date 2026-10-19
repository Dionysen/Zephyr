import '../models/llm_settings.dart';

abstract class LlmSettingsRepository {
  Future<LlmPreferences> loadPreferences();
  Future<void> savePreferences(LlmPreferences preferences);
  Future<String?> loadApiKey(LlmProviderKind provider);
  Future<void> saveApiKey(LlmProviderKind provider, String apiKey);
}
