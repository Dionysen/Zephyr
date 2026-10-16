import 'package:flutter/material.dart';

import '../../../../domain/models/llm_settings.dart';
import '../../settings/models/llm_thinking_labels.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';

Future<void> showWorkspaceAiChatOptionsSheet(BuildContext context) {
  return showZephyrModalSheet<void>(
    context: context,
    builder: (context) => const _WorkspaceAiChatOptionsSheet(),
  );
}

class _WorkspaceAiChatOptionsSheet extends StatelessWidget {
  const _WorkspaceAiChatOptionsSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = ZephyrScope.of(context).llmSettings;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final prefs = vm.preferences;
        final models = prefs.verifiedModelIds;
        final selectedModel = prefs.effectiveChatModelId;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.aiChatSessionOptionsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (models.isEmpty)
                  Text(
                    l10n.aiChatSessionOptionsNeedTest,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ZephyrSettingsSection(
                    children: [
                      ZephyrSettingsChoiceTile<String>(
                        icon: Icons.smart_toy_outlined,
                        title: l10n.llmModelTitle,
                        subtitle: l10n.aiChatSessionModelSubtitle,
                        selected: selectedModel,
                        valueLabel: selectedModel.isEmpty
                            ? l10n.llmModelNotSelected
                            : selectedModel,
                        choices: [
                          for (final id in models)
                            ZephyrSettingsChoice(value: id, label: id),
                        ],
                        onSelected: (id) {
                          if (id == prefs.selectedModelId) {
                            vm.setChatModelId('');
                          } else {
                            vm.setChatModelId(id);
                          }
                        },
                      ),
                      ZephyrSettingsChoiceTile<LlmThinkingLevel>(
                        icon: Icons.psychology_outlined,
                        title: l10n.llmThinkingLevelTitle,
                        subtitle: prefs.allowThinking
                            ? l10n.llmThinkingLevelSubtitle
                            : l10n.llmThinkingDisabledInSettings,
                        selected: prefs.chatThinkingLevel,
                        valueLabel: llmThinkingLevelLabel(
                          prefs.chatThinkingLevel,
                          l10n,
                        ),
                        choices: [
                          for (final level in kLlmSelectableThinkingLevels)
                            ZephyrSettingsChoice(
                              value: level,
                              label: llmThinkingLevelLabel(level, l10n),
                            ),
                        ],
                        onSelected: prefs.allowThinking
                            ? vm.setChatThinkingLevel
                            : (_) {},
                        showDivider: false,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
