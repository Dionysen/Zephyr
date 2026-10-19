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

/// Assistant reply with optional chain-of-thought text from the model.
class LlmChatResult {
  const LlmChatResult({
    this.text = '',
    this.thinking = '',
    this.thinkingInProgress = false,
  });

  final String text;
  final String thinking;
  final bool thinkingInProgress;

  bool get hasThinking => thinking.trim().isNotEmpty;

  LlmChatResult copyWith({
    String? text,
    String? thinking,
    bool? thinkingInProgress,
  }) => LlmChatResult(
    text: text ?? this.text,
    thinking: thinking ?? this.thinking,
    thinkingInProgress: thinkingInProgress ?? this.thinkingInProgress,
  );

  LlmChatResult applyPart(LlmStreamPart part) {
    return switch (part.kind) {
      LlmStreamPartKind.thinking => copyWith(
        thinking: thinking + part.delta,
        thinkingInProgress: true,
      ),
      LlmStreamPartKind.answer => copyWith(
        text: text + part.delta,
        thinkingInProgress: false,
      ),
    };
  }
}

enum LlmStreamPartKind { thinking, answer }

class LlmStreamPart {
  const LlmStreamPart({required this.kind, required this.delta});

  final LlmStreamPartKind kind;
  final String delta;
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
