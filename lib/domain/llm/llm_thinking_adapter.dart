import '../models/llm_settings.dart';

/// Provider-specific thinking / reasoning knobs derived from [LlmThinkingLevel].
class LlmThinkingRequest {
  const LlmThinkingRequest({
    this.openAiReasoningEffort,
    this.openAiThinking,
    this.anthropicThinking,
    this.googleThinkingBudget,
  });

  /// OpenAI o-series / Responses-style: `low` | `medium` | `high`.
  final String? openAiReasoningEffort;

  /// DeepSeek / some OpenAI-compatible: `{ "type": "enabled" }`.
  final Map<String, Object?>? openAiThinking;

  /// Anthropic extended thinking block.
  final Map<String, Object?>? anthropicThinking;

  /// Gemini `thinkingConfig.thinkingBudget` (tokens).
  final int? googleThinkingBudget;

  bool get isActive =>
      openAiReasoningEffort != null ||
      openAiThinking != null ||
      anthropicThinking != null ||
      googleThinkingBudget != null;
}

/// Maps a unified thinking level to vendor request fragments.
abstract final class LlmThinkingAdapter {
  static LlmThinkingRequest forRequest({
    required LlmProviderKind provider,
    required LlmThinkingLevel level,
    required String modelId,
  }) {
    if (level == LlmThinkingLevel.off) {
      return const LlmThinkingRequest();
    }
    if (level == LlmThinkingLevel.auto) {
      return _autoFor(provider: provider, modelId: modelId);
    }
    return switch (provider) {
      LlmProviderKind.anthropic => _anthropic(level),
      LlmProviderKind.google => _google(level),
      LlmProviderKind.openai ||
      LlmProviderKind.deepseek ||
      LlmProviderKind.zhipu ||
      LlmProviderKind.openAiCompatible => _openAiCompatible(
        level,
        modelId,
        provider,
      ),
    };
  }

  static LlmThinkingRequest _autoFor({
    required LlmProviderKind provider,
    required String modelId,
  }) {
    if (_prefersReasoningEffort(modelId)) {
      return const LlmThinkingRequest(openAiReasoningEffort: 'medium');
    }
    if (provider == LlmProviderKind.anthropic) {
      return _anthropic(LlmThinkingLevel.medium);
    }
    if (provider == LlmProviderKind.google) {
      return _google(LlmThinkingLevel.medium);
    }
    if (_prefersThinkingBlock(modelId, provider)) {
      return const LlmThinkingRequest(
        openAiThinking: {'type': 'enabled'},
      );
    }
    return const LlmThinkingRequest();
  }

  static LlmThinkingRequest _openAiCompatible(
    LlmThinkingLevel level,
    String modelId,
    LlmProviderKind provider,
  ) {
    if (_prefersReasoningEffort(modelId)) {
      return LlmThinkingRequest(
        openAiReasoningEffort: _effortName(level),
      );
    }
    if (_prefersThinkingBlock(modelId, provider)) {
      return const LlmThinkingRequest(
        openAiThinking: {'type': 'enabled'},
      );
    }
    // Generic OpenAI-compatible: try reasoning_effort when level is not low.
    if (level == LlmThinkingLevel.minimal) {
      return const LlmThinkingRequest(openAiReasoningEffort: 'low');
    }
    return LlmThinkingRequest(openAiReasoningEffort: _effortName(level));
  }

  static LlmThinkingRequest _anthropic(LlmThinkingLevel level) {
    final budget = switch (level) {
      LlmThinkingLevel.minimal => 2048,
      LlmThinkingLevel.low => 4096,
      LlmThinkingLevel.medium => 8192,
      LlmThinkingLevel.high => 16384,
      LlmThinkingLevel.off || LlmThinkingLevel.auto => 0,
    };
    if (budget <= 0) return const LlmThinkingRequest();
    return LlmThinkingRequest(
      anthropicThinking: {
        'type': 'enabled',
        'budget_tokens': budget,
      },
    );
  }

  static LlmThinkingRequest _google(LlmThinkingLevel level) {
    final budget = switch (level) {
      LlmThinkingLevel.minimal => 512,
      LlmThinkingLevel.low => 2048,
      LlmThinkingLevel.medium => 8192,
      LlmThinkingLevel.high => 24576,
      LlmThinkingLevel.off || LlmThinkingLevel.auto => 0,
    };
    if (budget <= 0) return const LlmThinkingRequest();
    return LlmThinkingRequest(googleThinkingBudget: budget);
  }

  static String _effortName(LlmThinkingLevel level) => switch (level) {
    LlmThinkingLevel.minimal || LlmThinkingLevel.low => 'low',
    LlmThinkingLevel.medium => 'medium',
    LlmThinkingLevel.high => 'high',
    LlmThinkingLevel.off || LlmThinkingLevel.auto => 'medium',
  };

  static bool _prefersReasoningEffort(String modelId) {
    final id = modelId.toLowerCase();
    return id.contains('o1') ||
        id.contains('o3') ||
        id.contains('o4') ||
        id.contains('gpt-5') ||
        id.contains('reasoning');
  }

  static bool _prefersThinkingBlock(String modelId, LlmProviderKind provider) {
    if (provider == LlmProviderKind.deepseek) return true;
    if (provider == LlmProviderKind.zhipu) return true;
    final id = modelId.toLowerCase();
    return id.contains('reasoner') || id.contains('thinking') || id.contains('r1');
  }
}
