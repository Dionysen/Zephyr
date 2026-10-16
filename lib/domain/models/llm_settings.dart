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
  });

  final LlmProviderKind provider;
  final String customBaseUrl;
  final String selectedModelId;
  final List<String> verifiedModelIds;

  static const defaults = LlmPreferences();

  bool get hasVerifiedModels => verifiedModelIds.isNotEmpty;

  LlmPreferences copyWith({
    LlmProviderKind? provider,
    String? customBaseUrl,
    String? selectedModelId,
    List<String>? verifiedModelIds,
    bool clearVerifiedModels = false,
    bool clearSelectedModel = false,
  }) => LlmPreferences(
    provider: provider ?? this.provider,
    customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    selectedModelId: clearSelectedModel
        ? ''
        : (selectedModelId ?? this.selectedModelId),
    verifiedModelIds: clearVerifiedModels
        ? const []
        : (verifiedModelIds ?? this.verifiedModelIds),
  );

  Map<String, Object?> toJson() => {
    'provider': provider.name,
    'customBaseUrl': customBaseUrl,
    'selectedModelId': selectedModelId,
    'verifiedModelIds': verifiedModelIds,
  };

  static LlmPreferences fromJson(Map<String, dynamic>? map) {
    if (map == null) return defaults;
    final providerName = map['provider'] as String? ?? LlmProviderKind.deepseek.name;
    final provider = LlmProviderKind.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => LlmProviderKind.deepseek,
    );
    final models = map['verifiedModelIds'];
    return LlmPreferences(
      provider: provider,
      customBaseUrl: map['customBaseUrl'] as String? ?? '',
      selectedModelId: map['selectedModelId'] as String? ?? '',
      verifiedModelIds: models is List
          ? models.map((e) => e.toString()).toList(growable: false)
          : const [],
    );
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
