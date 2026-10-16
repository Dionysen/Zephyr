import 'package:flutter/foundation.dart';

import '../../../../data/services/llm_gateway.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../../../domain/repositories/llm_settings_repository.dart';

class LlmSettingsViewModel extends ChangeNotifier {
  LlmSettingsViewModel({
    required LlmSettingsRepository repository,
    LlmGateway? gateway,
  }) : _repository = repository,
       _gateway = gateway ?? LlmGateway();

  final LlmSettingsRepository _repository;
  final LlmGateway _gateway;

  LlmPreferences _preferences = LlmPreferences.defaults;
  var _apiKey = '';
  var _testing = false;
  var _chatting = false;
  Object? _error;

  LlmPreferences get preferences => _preferences;
  String get apiKey => _apiKey;
  bool get testing => _testing;
  bool get chatting => _chatting;
  Object? get error => _error;

  bool get isConfigured =>
      _apiKey.trim().isNotEmpty && _preferences.selectedModelId.isNotEmpty;

  LlmConnection get connection => LlmConnection(
    provider: _preferences.provider,
    apiKey: _apiKey,
    customBaseUrl: _preferences.customBaseUrl,
  );

  Future<void> load() async {
    _preferences = await _repository.loadPreferences();
    _apiKey = await _repository.loadApiKey(_preferences.provider) ?? '';
    _error = null;
    notifyListeners();
  }

  Future<void> setProvider(LlmProviderKind provider) async {
    if (_preferences.provider == provider) return;
    _preferences = _preferences.copyWith(
      provider: provider,
      clearVerifiedModels: true,
      clearSelectedModel: true,
    );
    await _repository.savePreferences(_preferences);
    _apiKey = await _repository.loadApiKey(provider) ?? '';
    _error = null;
    notifyListeners();
  }

  Future<void> setApiKey(String value) async {
    _apiKey = value;
    await _repository.saveApiKey(_preferences.provider, value);
    _error = null;
    notifyListeners();
  }

  Future<void> setCustomBaseUrl(String value) async {
    _preferences = _preferences.copyWith(
      customBaseUrl: value.trim(),
      clearVerifiedModels: true,
      clearSelectedModel: true,
    );
    await _repository.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> selectModel(String modelId) async {
    _preferences = _preferences.copyWith(selectedModelId: modelId);
    await _repository.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> testConnection() async {
    if (_testing) return;
    _testing = true;
    _error = null;
    notifyListeners();
    try {
      final models = await _gateway.listModels(connection);
      if (models.isEmpty) {
        throw LlmGatewayException('No models returned.');
      }
      final ids = models.map((m) => m.id).toList(growable: false);
      var selected = _preferences.selectedModelId;
      if (selected.isEmpty || !ids.contains(selected)) {
        selected = ids.first;
      }
      _preferences = _preferences.copyWith(
        verifiedModelIds: ids,
        selectedModelId: selected,
      );
      await _repository.savePreferences(_preferences);
      _error = null;
    } on Object catch (error) {
      _error = error;
      _preferences = _preferences.copyWith(
        clearVerifiedModels: true,
        clearSelectedModel: true,
      );
      await _repository.savePreferences(_preferences);
    } finally {
      _testing = false;
      notifyListeners();
    }
  }

  Future<String> completeChat({
    required List<LlmChatMessage> messages,
  }) async {
    if (_chatting) {
      throw StateError('Chat request already in progress.');
    }
    if (!isConfigured) {
      throw LlmGatewayException('Configure API key and model in settings.');
    }
    _chatting = true;
    _error = null;
    notifyListeners();
    try {
      return await _gateway.completeChat(
        connection: connection,
        modelId: _preferences.selectedModelId,
        messages: messages,
      );
    } on Object catch (error) {
      _error = error;
      rethrow;
    } finally {
      _chatting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
