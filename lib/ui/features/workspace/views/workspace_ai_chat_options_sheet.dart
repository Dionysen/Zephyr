import 'package:flutter/material.dart';

import '../../../../domain/models/llm_settings.dart';
import '../../settings/models/llm_thinking_labels.dart';
import '../../settings/views/llm_settings_view.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';

void _openAiModelSettingsFromChat(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.pop();
  navigator.push(LlmSettingsPage.route());
}

Future<void> showWorkspaceAiChatOptionsSheet(
  BuildContext context, {
  VoidCallback? onManageSessions,
}) {
  return showZephyrModalSheet<void>(
    context: context,
    builder: (context) => _WorkspaceAiChatOptionsSheet(
      onManageSessions: onManageSessions,
    ),
  );
}

class _WorkspaceAiChatOptionsSheet extends StatelessWidget {
  const _WorkspaceAiChatOptionsSheet({this.onManageSessions});

  final VoidCallback? onManageSessions;

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
                if (onManageSessions != null)
                  ZephyrSettingsSection(
                    children: [
                      ZephyrSettingsListTile(
                        icon: Icons.forum_outlined,
                        title: l10n.aiChatSessionsTitle,
                        subtitle: l10n.aiChatSessionsSubtitle,
                        onTap: () {
                          Navigator.of(context).pop();
                          onManageSessions!();
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                if (onManageSessions != null) const SizedBox(height: 12),
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
                        selected: prefs.resolvedChatThinkingLevel(),
                        valueLabel: llmThinkingLevelLabel(
                          prefs.resolvedChatThinkingLevel(),
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
                const SizedBox(height: 12),
                ZephyrSettingsSection(
                  children: [
                    ZephyrSettingsListTile(
                      icon: Icons.auto_awesome_outlined,
                      title: l10n.aiChatAiSettingsEntry,
                      subtitle: l10n.llmSettingsSubtitle,
                      showDivider: false,
                      onTap: () => _openAiModelSettingsFromChat(context),
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
