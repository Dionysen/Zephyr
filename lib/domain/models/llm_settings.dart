/// Default per-request token ceilings (user-editable in settings).
const int kLlmDefaultMaxInputTokens = 125000;
const int kLlmDefaultMaxOutputTokens = 4096;

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

/// Per-vendor connection profile (models + optional base URL).
class LlmProviderProfile {
  const LlmProviderProfile({
    this.customBaseUrl = '',
    this.selectedModelId = '',
    this.verifiedModelIds = const [],
  });

  final String customBaseUrl;
  final String selectedModelId;
  final List<String> verifiedModelIds;

  bool get hasVerifiedModels => verifiedModelIds.isNotEmpty;

  LlmProviderProfile copyWith({
    String? customBaseUrl,
    String? selectedModelId,
    List<String>? verifiedModelIds,
    bool clearVerifiedModels = false,
    bool clearSelectedModel = false,
  }) => LlmProviderProfile(
    customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    selectedModelId: clearSelectedModel
        ? ''
        : (selectedModelId ?? this.selectedModelId),
    verifiedModelIds: clearVerifiedModels
        ? const []
        : (verifiedModelIds ?? this.verifiedModelIds),
  );

  Map<String, Object?> toJson() => {
    'customBaseUrl': customBaseUrl,
    'selectedModelId': selectedModelId,
    'verifiedModelIds': verifiedModelIds,
  };

  static LlmProviderProfile fromJson(Map<String, dynamic>? map) {
    if (map == null) return const LlmProviderProfile();
    final models = map['verifiedModelIds'];
    return LlmProviderProfile(
      customBaseUrl: map['customBaseUrl'] as String? ?? '',
      selectedModelId: map['selectedModelId'] as String? ?? '',
      verifiedModelIds: models is List
          ? models.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
  }
}

/// Non-secret LLM configuration persisted under app support.
class LlmPreferences {
  const LlmPreferences({
    this.provider = LlmProviderKind.deepseek,
    this.providerProfiles = const {},
    this.chatProvider,
    this.streamOutput = false,
    this.presetSystemPrompt = '',
    this.maxInputTokens = kLlmDefaultMaxInputTokens,
    this.maxOutputTokens = kLlmDefaultMaxOutputTokens,
    this.allowThinking = false,
    this.defaultThinkingLevel = LlmThinkingLevel.auto,
    this.chatModelId = '',
    this.chatThinkingLevel = LlmThinkingLevel.auto,
    this.chatThinkingLevelByModelId = const {},
  });

  /// Provider shown in AI model settings (editing target).
  final LlmProviderKind provider;

  /// Saved model lists and URLs per [LlmProviderKind].
  final Map<LlmProviderKind, LlmProviderProfile> providerProfiles;

  /// Assistant chat vendor; null uses [provider].
  final LlmProviderKind? chatProvider;
  final bool streamOutput;
  final String presetSystemPrompt;
  final int maxInputTokens;
  final int maxOutputTokens;
  final bool allowThinking;
  final LlmThinkingLevel defaultThinkingLevel;

  /// Empty uses [selectedModelId] in the chat composer.
  final String chatModelId;
  final LlmThinkingLevel chatThinkingLevel;

  /// Per verified chat model id; used when switching models in the composer.
  final Map<String, LlmThinkingLevel> chatThinkingLevelByModelId;

  static const defaults = LlmPreferences();

  LlmProviderProfile profileFor(LlmProviderKind kind) =>
      providerProfiles[kind] ?? const LlmProviderProfile();

  String get customBaseUrl => profileFor(provider).customBaseUrl;

  String get selectedModelId => profileFor(provider).selectedModelId;

  List<String> get verifiedModelIds => profileFor(provider).verifiedModelIds;

  bool get hasVerifiedModels => verifiedModelIds.isNotEmpty;

  LlmProviderKind get effectiveChatProvider => chatProvider ?? provider;

  LlmProviderProfile get chatProfile => profileFor(effectiveChatProvider);

  String get effectiveChatModelId {
    if (chatModelId.isNotEmpty) return chatModelId;
    return chatProfile.selectedModelId;
  }

  /// Thinking level for [modelId], or the active chat model when omitted.
  LlmThinkingLevel resolvedChatThinkingLevel([String? modelId]) {
    if (!allowThinking) return LlmThinkingLevel.off;
    final id = modelId ?? effectiveChatModelId;
    if (id.isNotEmpty) {
      final mapped = chatThinkingLevelByModelId[id];
      if (mapped != null) return mapped;
    }
    return chatThinkingLevel;
  }

  /// Level used for the next chat request (composer overrides settings default).
  LlmThinkingLevel effectiveThinkingLevel() => resolvedChatThinkingLevel();

  LlmPreferences withChatThinkingForModel(
    String modelId,
    LlmThinkingLevel level,
  ) {
    if (modelId.isEmpty) {
      return copyWith(chatThinkingLevel: level);
    }
    final map = Map<String, LlmThinkingLevel>.from(chatThinkingLevelByModelId);
    map[modelId] = level;
    final syncCurrent = modelId == effectiveChatModelId;
    return copyWith(
      chatThinkingLevelByModelId: map,
      chatThinkingLevel: syncCurrent ? level : chatThinkingLevel,
    );
  }

  LlmPreferences withProviderProfile(
    LlmProviderKind kind,
    LlmProviderProfile profile,
  ) {
    final map = Map<LlmProviderKind, LlmProviderProfile>.from(providerProfiles);
    map[kind] = profile;
    return copyWith(providerProfiles: map);
  }

  LlmPreferences copyWith({
    LlmProviderKind? provider,
    Map<LlmProviderKind, LlmProviderProfile>? providerProfiles,
    LlmProviderKind? chatProvider,
    bool clearChatProvider = false,
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
    Map<String, LlmThinkingLevel>? chatThinkingLevelByModelId,
    bool clearVerifiedModels = false,
    bool clearSelectedModel = false,
    bool clearChatModel = false,
  }) {
    final editing = provider ?? this.provider;
    var profiles = Map<LlmProviderKind, LlmProviderProfile>.from(
      providerProfiles ?? this.providerProfiles,
    );
    if (customBaseUrl != null ||
        selectedModelId != null ||
        verifiedModelIds != null ||
        clearVerifiedModels ||
        clearSelectedModel) {
      final current = profiles[editing] ?? const LlmProviderProfile();
      profiles[editing] = current.copyWith(
        customBaseUrl: customBaseUrl,
        selectedModelId: selectedModelId,
        verifiedModelIds: verifiedModelIds,
        clearVerifiedModels: clearVerifiedModels,
        clearSelectedModel: clearSelectedModel,
      );
    }
    return LlmPreferences(
      provider: editing,
      providerProfiles: profiles,
      chatProvider: clearChatProvider
          ? null
          : (chatProvider ?? this.chatProvider),
      streamOutput: streamOutput ?? this.streamOutput,
      presetSystemPrompt: presetSystemPrompt ?? this.presetSystemPrompt,
      maxInputTokens: maxInputTokens ?? this.maxInputTokens,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      allowThinking: allowThinking ?? this.allowThinking,
      defaultThinkingLevel:
          defaultThinkingLevel ?? this.defaultThinkingLevel,
      chatModelId: clearChatModel ? '' : (chatModelId ?? this.chatModelId),
      chatThinkingLevel: chatThinkingLevel ?? this.chatThinkingLevel,
      chatThinkingLevelByModelId:
          chatThinkingLevelByModelId ?? this.chatThinkingLevelByModelId,
    );
  }

  Map<String, Object?> toJson() {
    final active = profileFor(provider);
    return {
    'provider': provider.name,
    if (chatProvider != null) 'chatProvider': chatProvider!.name,
    'providerProfiles': {
      for (final entry in providerProfiles.entries)
        entry.key.name: entry.value.toJson(),
    },
    // Legacy mirror for older builds.
    'customBaseUrl': active.customBaseUrl,
    'selectedModelId': active.selectedModelId,
    'verifiedModelIds': active.verifiedModelIds,
    'streamOutput': streamOutput,
    'presetSystemPrompt': presetSystemPrompt,
    'maxInputTokens': maxInputTokens,
    'maxOutputTokens': maxOutputTokens,
    'allowThinking': allowThinking,
    'defaultThinkingLevel': defaultThinkingLevel.name,
    'chatModelId': chatModelId,
    'chatThinkingLevel': chatThinkingLevel.name,
    'chatThinkingLevelByModelId': {
      for (final entry in chatThinkingLevelByModelId.entries)
        entry.key: entry.value.name,
    },
    // Legacy key for older builds.
    'chatThinkingMode': chatThinkingLevel.name,
  };
  }

  static LlmPreferences fromJson(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    final providerName = map['provider'] as String? ?? LlmProviderKind.deepseek.name;
    final provider = LlmProviderKind.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => LlmProviderKind.deepseek,
    );
    final chatProviderName = map['chatProvider'] as String?;
    final chatProvider = chatProviderName == null
        ? null
        : LlmProviderKind.values.firstWhere(
            (value) => value.name == chatProviderName,
            orElse: () => provider,
          );
    final profiles = <LlmProviderKind, LlmProviderProfile>{};
    final rawProfiles = map['providerProfiles'];
    if (rawProfiles is Map) {
      for (final entry in rawProfiles.entries) {
        final kind = LlmProviderKind.values.firstWhere(
          (value) => value.name == entry.key.toString(),
          orElse: () => LlmProviderKind.deepseek,
        );
        if (entry.value is Map) {
          profiles[kind] = LlmProviderProfile.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    if (profiles.isEmpty) {
      final models = map['verifiedModelIds'];
      profiles[provider] = LlmProviderProfile(
        customBaseUrl: map['customBaseUrl'] as String? ?? '',
        selectedModelId: map['selectedModelId'] as String? ?? '',
        verifiedModelIds: models is List
            ? models.map((e) => e.toString()).toList(growable: false)
            : const [],
      );
    }
    final chatLevel = _parseThinkingLevel(
      map['chatThinkingLevel'] as String? ?? map['chatThinkingMode'] as String?,
    );
    final defaultLevel = _parseThinkingLevel(
      map['defaultThinkingLevel'] as String?,
      fallback: LlmThinkingLevel.auto,
    );
    return LlmPreferences(
      provider: provider,
      providerProfiles: profiles,
      chatProvider: chatProvider,
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
      chatThinkingLevelByModelId: _readThinkingLevelByModel(
        map['chatThinkingLevelByModelId'],
      ),
    );
  }

  static Map<String, LlmThinkingLevel> _readThinkingLevelByModel(
    Object? raw,
  ) {
    if (raw is! Map) return const {};
    final out = <String, LlmThinkingLevel>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      if (key.isEmpty) continue;
      out[key] = _parseThinkingLevel(entry.value?.toString());
    }
    return out;
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
