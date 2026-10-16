import 'package:flutter/foundation.dart';

import '../../../../data/services/llm_gateway.dart';
import '../../../../domain/llm/llm_message_budget.dart';
import '../../../../domain/models/llm_chat.dart';
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
      _apiKey.trim().isNotEmpty && _preferences.effectiveChatModelId.isNotEmpty;

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

  Future<void> _persist(LlmPreferences prefs) async {
    _preferences = prefs;
    await _repository.savePreferences(prefs);
    notifyListeners();
  }

  Future<void> setProvider(LlmProviderKind provider) async {
    if (_preferences.provider == provider) return;
    await _persist(
      _preferences.copyWith(
        provider: provider,
        clearVerifiedModels: true,
        clearSelectedModel: true,
      ),
    );
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
    await _persist(
      _preferences.copyWith(
        customBaseUrl: value.trim(),
        clearVerifiedModels: true,
        clearSelectedModel: true,
      ),
    );
  }

  Future<void> selectModel(String modelId) async {
    await _persist(_preferences.copyWith(selectedModelId: modelId));
  }

  Future<void> setStreamOutput(bool value) async {
    await _persist(_preferences.copyWith(streamOutput: value));
  }

  Future<void> setPresetSystemPrompt(String value) async {
    await _persist(_preferences.copyWith(presetSystemPrompt: value));
  }

  Future<void> setMaxInputTokens(int value) async {
    await _persist(_preferences.copyWith(maxInputTokens: value));
  }

  Future<void> setMaxOutputTokens(int value) async {
    await _persist(_preferences.copyWith(maxOutputTokens: value));
  }

  Future<void> setAllowThinking(bool value) async {
    await _persist(_preferences.copyWith(allowThinking: value));
  }

  Future<void> setChatModelId(String modelId) async {
    await _persist(
      modelId.isEmpty
          ? _preferences.copyWith(clearChatModel: true)
          : _preferences.copyWith(chatModelId: modelId),
    );
  }

  Future<void> setDefaultThinkingLevel(LlmThinkingLevel level) async {
    await _persist(_preferences.copyWith(defaultThinkingLevel: level));
  }

  Future<void> setChatThinkingLevel(LlmThinkingLevel level) async {
    await _persist(_preferences.copyWith(chatThinkingLevel: level));
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
      await _persist(
        _preferences.copyWith(
          verifiedModelIds: ids,
          selectedModelId: selected,
        ),
      );
      _error = null;
    } on Object catch (error) {
      _error = error;
      await _persist(
        _preferences.copyWith(
          clearVerifiedModels: true,
          clearSelectedModel: true,
        ),
      );
    } finally {
      _testing = false;
      notifyListeners();
    }
  }

  List<LlmChatMessage> _prepareMessages(List<LlmChatMessage> messages) {
    final preset = _preferences.presetSystemPrompt.trim();
    final systemParts = <String>[];
    if (preset.isNotEmpty) systemParts.add(preset);
    for (final message in messages.where((m) => m.role == LlmChatRole.system)) {
      systemParts.add(message.text);
    }
    final nonSystem =
        messages.where((m) => m.role != LlmChatRole.system).toList(growable: false);
    final merged = <LlmChatMessage>[
      if (systemParts.isNotEmpty)
        LlmChatMessage(
          role: LlmChatRole.system,
          text: systemParts.join('\n\n'),
        ),
      ...nonSystem,
    ];
    return truncateMessagesForBudget(
      merged,
      maxInputTokens: _preferences.maxInputTokens,
    );
  }

  LlmCompletionOptions _completionOptions() => LlmCompletionOptions(
    maxOutputTokens: _preferences.maxOutputTokens,
    provider: _preferences.provider,
    modelId: _preferences.effectiveChatModelId,
    thinkingLevel: _preferences.effectiveThinkingLevel(),
  );

  Future<LlmChatResult> completeChat({
    required List<LlmChatMessage> messages,
    void Function(LlmChatResult partial)? onPartial,
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
      final prepared = _prepareMessages(messages);
      final modelId = _preferences.effectiveChatModelId;
      final options = _completionOptions();
      if (_preferences.streamOutput) {
        var result = const LlmChatResult();
        await for (final part in _gateway.streamChat(
          connection: connection,
          modelId: modelId,
          messages: prepared,
          options: options,
        )) {
          result = result.applyPart(part);
          onPartial?.call(result);
        }
        return result.copyWith(thinkingInProgress: false);
      }
      final result = await _gateway.completeChat(
        connection: connection,
        modelId: modelId,
        messages: prepared,
        options: options,
      );
      return result.copyWith(thinkingInProgress: false);
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
