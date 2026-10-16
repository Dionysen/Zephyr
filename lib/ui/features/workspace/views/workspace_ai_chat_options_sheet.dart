import 'package:flutter/material.dart';

import '../../../../domain/llm/llm_provider_catalog.dart';
import '../../../../domain/models/llm_settings.dart';
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

String _providerLabel(LlmProviderKind kind, AppLocalizations l10n) {
  final zh = l10n.localeName.startsWith('zh');
  return zh
      ? LlmProviderCatalog.labelZh(kind)
      : LlmProviderCatalog.labelEn(kind);
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
        final configured = vm.configuredProviders;
        final selected = prefs.effectiveChatProvider;
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
                if (configured.isEmpty)
                  Text(
                    l10n.aiChatSessionOptionsNeedTest,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  ZephyrSettingsSection(
                    children: [
                      ZephyrSettingsChoiceTile<LlmProviderKind>(
                        icon: Icons.hub_outlined,
                        title: l10n.aiChatSessionProviderTitle,
                        subtitle: l10n.aiChatSessionProviderSubtitle,
                        selected: selected,
                        valueLabel: _providerLabel(selected, l10n),
                        choices: [
                          for (final kind in configured)
                            ZephyrSettingsChoice(
                              value: kind,
                              label: _providerLabel(kind, l10n),
                            ),
                        ],
                        onSelected: vm.setChatProvider,
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
