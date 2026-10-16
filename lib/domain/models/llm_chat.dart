import 'llm_settings.dart';

enum LlmChatRole { system, user, assistant }

extension LlmChatRoleApi on LlmChatRole {
  String get apiName => switch (this) {
    LlmChatRole.system => 'system',
    LlmChatRole.user => 'user',
    LlmChatRole.assistant => 'assistant',
  };
}

class LlmChatMessage {
  const LlmChatMessage({required this.role, required this.text});

  final LlmChatRole role;
  final String text;
}

/// Per-request generation flags (non-persistent).
class LlmCompletionOptions {
  const LlmCompletionOptions({
    required this.maxOutputTokens,
    required this.provider,
    required this.modelId,
    required this.thinkingLevel,
  });

  final int maxOutputTokens;
  final LlmProviderKind provider;
  final String modelId;
  final LlmThinkingLevel thinkingLevel;
}
