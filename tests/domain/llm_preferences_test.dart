import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/llm_settings.dart';

void main() {
  test('LlmPreferences round-trips new fields', () {
    const prefs = LlmPreferences(
      streamOutput: true,
      presetSystemPrompt: 'You are helpful.',
      maxInputTokens: 125000,
      maxOutputTokens: 8000,
      allowThinking: true,
      defaultThinkingLevel: LlmThinkingLevel.medium,
      chatModelId: 'deepseek-reasoner',
      chatThinkingLevel: LlmThinkingLevel.high,
    );
    final restored = LlmPreferences.fromJson(prefs.toJson());
    expect(restored.streamOutput, isTrue);
    expect(restored.presetSystemPrompt, 'You are helpful.');
    expect(restored.maxInputTokens, 125000);
    expect(restored.maxOutputTokens, 8000);
    expect(restored.allowThinking, isTrue);
    expect(restored.defaultThinkingLevel, LlmThinkingLevel.medium);
    expect(restored.chatModelId, 'deepseek-reasoner');
    expect(restored.chatThinkingLevel, LlmThinkingLevel.high);
    expect(restored.effectiveChatModelId, 'deepseek-reasoner');
  });

  test('migrates legacy chatThinkingMode names', () {
    final restored = LlmPreferences.fromJson({
      'chatThinkingMode': 'enabled',
    });
    expect(restored.chatThinkingLevel, LlmThinkingLevel.medium);
  });

  test('effectiveThinkingLevel respects allowThinking', () {
    const blocked = LlmPreferences(
      allowThinking: false,
      chatThinkingLevel: LlmThinkingLevel.high,
    );
    const active = LlmPreferences(
      allowThinking: true,
      chatThinkingLevel: LlmThinkingLevel.low,
    );
    expect(blocked.effectiveThinkingLevel(), LlmThinkingLevel.off);
    expect(active.effectiveThinkingLevel(), LlmThinkingLevel.low);
  });
}
