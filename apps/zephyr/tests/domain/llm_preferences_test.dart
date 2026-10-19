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

  test('migrates legacy single-provider fields into profiles', () {
    final restored = LlmPreferences.fromJson({
      'provider': 'openai',
      'customBaseUrl': 'https://example.com/v1',
      'selectedModelId': 'gpt-4',
      'verifiedModelIds': ['gpt-4', 'gpt-4o'],
    });
    final profile = restored.profileFor(LlmProviderKind.openai);
    expect(profile.customBaseUrl, 'https://example.com/v1');
    expect(profile.selectedModelId, 'gpt-4');
    expect(profile.verifiedModelIds, ['gpt-4', 'gpt-4o']);
  });

  test('providerProfiles round-trip separately per vendor', () {
    const prefs = LlmPreferences(
      provider: LlmProviderKind.deepseek,
      providerProfiles: {
        LlmProviderKind.deepseek: LlmProviderProfile(
          selectedModelId: 'deepseek-chat',
          verifiedModelIds: ['deepseek-chat'],
        ),
        LlmProviderKind.openai: LlmProviderProfile(
          selectedModelId: 'gpt-4o',
          verifiedModelIds: ['gpt-4o'],
        ),
      },
      chatProvider: LlmProviderKind.openai,
    );
    final restored = LlmPreferences.fromJson(prefs.toJson());
    expect(restored.effectiveChatProvider, LlmProviderKind.openai);
    expect(restored.effectiveChatModelId, 'gpt-4o');
    expect(
      restored.profileFor(LlmProviderKind.deepseek).selectedModelId,
      'deepseek-chat',
    );
  });

  test('resolvedChatThinkingLevel uses per-model map', () {
    const prefs = LlmPreferences(
      allowThinking: true,
      providerProfiles: {
        LlmProviderKind.deepseek: LlmProviderProfile(
          selectedModelId: 'model-a',
        ),
      },
      chatThinkingLevel: LlmThinkingLevel.auto,
      chatThinkingLevelByModelId: {
        'model-a': LlmThinkingLevel.high,
        'model-b': LlmThinkingLevel.low,
      },
    );
    expect(prefs.resolvedChatThinkingLevel('model-a'), LlmThinkingLevel.high);
    expect(prefs.resolvedChatThinkingLevel('model-b'), LlmThinkingLevel.low);
    expect(
      prefs.resolvedChatThinkingLevel('model-c'),
      LlmThinkingLevel.auto,
    );
  });

  test('chatThinkingLevelByModelId round-trips in json', () {
    const prefs = LlmPreferences(
      chatThinkingLevelByModelId: {
        'gpt-4': LlmThinkingLevel.medium,
      },
    );
    final restored = LlmPreferences.fromJson(prefs.toJson());
    expect(
      restored.chatThinkingLevelByModelId['gpt-4'],
      LlmThinkingLevel.medium,
    );
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
