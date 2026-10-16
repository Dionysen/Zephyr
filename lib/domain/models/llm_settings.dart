/// Default per-request token ceilings (user-editable in settings).
const int kLlmDefaultMaxInputTokens = 125000;
const int kLlmDefaultMaxOutputTokens = 125000;

/// Unified thinking intensity (mapped per vendor in [LlmThinkingAdapter]).
enum LlmThinkingLevel {
  off,
  /// Light reasoning / small thinking budget.
  minimal,
  low,
  medium,
  high,
  /// Let the adapter pick a sensible default for the model.
  auto,
}

/// Supported third-party LLM vendors.
enum LlmProviderKind {
  openai,
  deepseek,
  anthropic,
  google,
  zhipu,
  openAiCompatible,
}

/// Non-secret LLM configuration persisted under app support.
class LlmPreferences {
  const LlmPreferences({
    this.provider = LlmProviderKind.deepseek,
    this.customBaseUrl = '',
    this.selectedModelId = '',
    this.verifiedModelIds = const [],
    this.streamOutput = false,
    this.presetSystemPrompt = '',
    this.maxInputTokens = kLlmDefaultMaxInputTokens,
    this.maxOutputTokens = kLlmDefaultMaxOutputTokens,
    this.allowThinking = false,
    this.defaultThinkingLevel = LlmThinkingLevel.auto,
    this.chatModelId = '',
    this.chatThinkingLevel = LlmThinkingLevel.auto,
  });

  final LlmProviderKind provider;
  final String customBaseUrl;
  final String selectedModelId;
  final List<String> verifiedModelIds;
  final bool streamOutput;
  final String presetSystemPrompt;
  final int maxInputTokens;
  final int maxOutputTokens;
  final bool allowThinking;
  final LlmThinkingLevel defaultThinkingLevel;

  /// Empty uses [selectedModelId] in the chat composer.
  final String chatModelId;
  final LlmThinkingLevel chatThinkingLevel;

  static const defaults = LlmPreferences();

  bool get hasVerifiedModels => verifiedModelIds.isNotEmpty;

  String get effectiveChatModelId =>
      chatModelId.isNotEmpty ? chatModelId : selectedModelId;

  /// Level used for the next chat request (composer overrides settings default).
  LlmThinkingLevel effectiveThinkingLevel() {
    if (!allowThinking) return LlmThinkingLevel.off;
    return chatThinkingLevel;
  }

  LlmPreferences copyWith({
    LlmProviderKind? provider,
    String? customBaseUrl,
    String? selectedModelId,
    List<String>? verifiedModelIds,
    bool? streamOutput,
    String? presetSystemPrompt,
    int? maxInputTokens,
    int? maxOutputTokens,
    bool? allowThinking,
    LlmThinkingLevel? defaultThinkingLevel,
    String? chatModelId,
    LlmThinkingLevel? chatThinkingLevel,
    bool clearVerifiedModels = false,
    bool clearSelectedModel = false,
    bool clearChatModel = false,
  }) => LlmPreferences(
    provider: provider ?? this.provider,
    customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    selectedModelId: clearSelectedModel
        ? ''
        : (selectedModelId ?? this.selectedModelId),
    verifiedModelIds: clearVerifiedModels
        ? const []
        : (verifiedModelIds ?? this.verifiedModelIds),
    streamOutput: streamOutput ?? this.streamOutput,
    presetSystemPrompt: presetSystemPrompt ?? this.presetSystemPrompt,
    maxInputTokens: maxInputTokens ?? this.maxInputTokens,
    maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
    allowThinking: allowThinking ?? this.allowThinking,
    defaultThinkingLevel:
        defaultThinkingLevel ?? this.defaultThinkingLevel,
    chatModelId: clearChatModel ? '' : (chatModelId ?? this.chatModelId),
    chatThinkingLevel: chatThinkingLevel ?? this.chatThinkingLevel,
  );

  Map<String, Object?> toJson() => {
    'provider': provider.name,
    'customBaseUrl': customBaseUrl,
    'selectedModelId': selectedModelId,
    'verifiedModelIds': verifiedModelIds,
    'streamOutput': streamOutput,
    'presetSystemPrompt': presetSystemPrompt,
    'maxInputTokens': maxInputTokens,
    'maxOutputTokens': maxOutputTokens,
    'allowThinking': allowThinking,
    'defaultThinkingLevel': defaultThinkingLevel.name,
    'chatModelId': chatModelId,
    'chatThinkingLevel': chatThinkingLevel.name,
    // Legacy key for older builds.
    'chatThinkingMode': chatThinkingLevel.name,
  };

  static LlmPreferences fromJson(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    final providerName = map['provider'] as String? ?? LlmProviderKind.deepseek.name;
    final provider = LlmProviderKind.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => LlmProviderKind.deepseek,
    );
    final models = map['verifiedModelIds'];
    final chatLevel = _parseThinkingLevel(
      map['chatThinkingLevel'] as String? ?? map['chatThinkingMode'] as String?,
    );
    final defaultLevel = _parseThinkingLevel(
      map['defaultThinkingLevel'] as String?,
      fallback: LlmThinkingLevel.auto,
    );
    return LlmPreferences(
      provider: provider,
      customBaseUrl: map['customBaseUrl'] as String? ?? '',
      selectedModelId: map['selectedModelId'] as String? ?? '',
      verifiedModelIds: models is List
          ? models.map((e) => e.toString()).toList(growable: false)
          : const [],
      streamOutput: map['streamOutput'] as bool? ?? false,
      presetSystemPrompt: map['presetSystemPrompt'] as String? ?? '',
      maxInputTokens: _readInt(
        map['maxInputTokens'],
        kLlmDefaultMaxInputTokens,
      ),
      maxOutputTokens: _readInt(
        map['maxOutputTokens'],
        kLlmDefaultMaxOutputTokens,
      ),
      allowThinking: map['allowThinking'] as bool? ?? false,
      defaultThinkingLevel: defaultLevel,
      chatModelId: map['chatModelId'] as String? ?? '',
      chatThinkingLevel: chatLevel,
    );
  }

  static LlmThinkingLevel _parseThinkingLevel(
    String? raw, {
    LlmThinkingLevel fallback = LlmThinkingLevel.auto,
  }) {
    if (raw == null || raw.isEmpty) return fallback;
    switch (raw) {
      case 'disabled':
        return LlmThinkingLevel.off;
      case 'enabled':
        return LlmThinkingLevel.medium;
      case 'defaultMode':
        return LlmThinkingLevel.auto;
    }
    return LlmThinkingLevel.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => fallback,
    );
  }

  static int _readInt(Object? raw, int fallback) {
    if (raw is int) return raw.clamp(1024, 2000000);
    if (raw is num) return raw.toInt().clamp(1024, 2000000);
    return fallback;
  }
}

/// One model entry returned from a connection test.
class LlmModelOption {
  const LlmModelOption({required this.id, this.displayName});

  final String id;
  final String? displayName;

  String get label => (displayName == null || displayName!.isEmpty) ? id : displayName!;
}

/// Runtime credentials + profile used for HTTP calls (not persisted as a unit).
class LlmConnection {
  const LlmConnection({
    required this.provider,
    required this.apiKey,
    this.customBaseUrl = '',
  });

  final LlmProviderKind provider;
  final String apiKey;
  final String customBaseUrl;
}
