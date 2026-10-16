import '../../../../domain/models/llm_settings.dart';
import '../../../core/zephyr_l10n.dart';

String llmThinkingLevelLabel(LlmThinkingLevel level, AppLocalizations l10n) =>
    switch (level) {
      LlmThinkingLevel.off => l10n.llmThinkingOff,
      LlmThinkingLevel.minimal => l10n.llmThinkingMinimal,
      LlmThinkingLevel.low => l10n.llmThinkingLow,
      LlmThinkingLevel.medium => l10n.llmThinkingMedium,
      LlmThinkingLevel.high => l10n.llmThinkingHigh,
      LlmThinkingLevel.auto => l10n.llmThinkingAuto,
    };

/// Levels offered in UI when [allowThinking] is on.
const kLlmSelectableThinkingLevels = [
  LlmThinkingLevel.off,
  LlmThinkingLevel.minimal,
  LlmThinkingLevel.low,
  LlmThinkingLevel.medium,
  LlmThinkingLevel.high,
  LlmThinkingLevel.auto,
];
