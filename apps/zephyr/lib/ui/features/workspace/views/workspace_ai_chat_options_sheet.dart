import 'package:flutter/material.dart';

import '../../../../domain/llm/llm_provider_catalog.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../settings/views/llm_settings_view.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';

void _openAiModelSettingsFromChat(
  BuildContext context, {
  VoidCallback? onOpenDesktopAiSettings,
}) {
  final navigator = Navigator.of(context);
  navigator.pop();
  if (onOpenDesktopAiSettings != null) {
    onOpenDesktopAiSettings();
    return;
  }
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
  VoidCallback? onNewConversation,
  VoidCallback? onManageSessions,
  VoidCallback? onOpenDesktopAiSettings,
}) {
  return showZephyrModalSheet<void>(
    context: context,
    builder: (context) => _WorkspaceAiChatOptionsSheet(
      onNewConversation: onNewConversation,
      onManageSessions: onManageSessions,
      onOpenDesktopAiSettings: onOpenDesktopAiSettings,
    ),
  );
}

class _WorkspaceAiChatOptionsSheet extends StatelessWidget {
  const _WorkspaceAiChatOptionsSheet({
    this.onNewConversation,
    this.onManageSessions,
    this.onOpenDesktopAiSettings,
  });

  final VoidCallback? onNewConversation;
  final VoidCallback? onManageSessions;
  final VoidCallback? onOpenDesktopAiSettings;

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
        final groupChildren = <Widget>[
          if (onManageSessions != null)
            ZephyrSettingsListTile(
              icon: Icons.forum_outlined,
              title: l10n.aiChatSessionsTitle,
              subtitle: l10n.aiChatSessionsSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                onManageSessions!();
              },
            ),
          if (configured.isEmpty)
            ZephyrSettingsListTile(
              icon: Icons.hub_outlined,
              title: l10n.aiChatSessionProviderTitle,
              subtitle: l10n.aiChatSessionOptionsNeedTest,
              onTap: () => _openAiModelSettingsFromChat(
                context,
                onOpenDesktopAiSettings: onOpenDesktopAiSettings,
              ),
            )
          else
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
            ),
          ZephyrSettingsListTile(
            icon: Icons.auto_awesome_outlined,
            title: l10n.aiChatAiSettingsEntry,
            subtitle: l10n.llmSettingsSubtitle,
            showDivider: false,
            onTap: () => _openAiModelSettingsFromChat(
              context,
              onOpenDesktopAiSettings: onOpenDesktopAiSettings,
            ),
          ),
        ];
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
                if (onNewConversation != null)
                  ZephyrSettingsSection(
                    children: [
                      ZephyrSettingsListTile(
                        icon: Icons.add_comment_outlined,
                        title: l10n.aiChatNewSession,
                        showDivider: false,
                        onTap: () {
                          Navigator.of(context).pop();
                          onNewConversation!();
                        },
                      ),
                    ],
                  ),
                if (onNewConversation != null) const SizedBox(height: 12),
                if (groupChildren.isNotEmpty)
                  ZephyrSettingsSection(children: groupChildren),
              ],
            ),
          ),
        );
      },
    );
  }
}
