import 'package:flutter/material.dart';

import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import 'llm_settings_content.dart';

/// AI assistant toggles plus model / chat configuration.
class AiSettingsView extends StatelessWidget {
  const AiSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    final l10n = context.l10n;
    final themeVm = scope.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ZephyrSettingsSection(
          children: [
            ListenableBuilder(
              listenable: themeVm,
              builder: (context, _) => ZephyrSettingsSwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: l10n.aiFeaturesEnabledTitle,
                subtitle: l10n.aiFeaturesEnabledSubtitle,
                value: themeVm.ui.aiFeaturesEnabled,
                onChanged: themeVm.updateAiFeaturesEnabled,
              ),
            ),
            ListenableBuilder(
              listenable: themeVm,
              builder: (context, _) => ZephyrSettingsSwitchTile(
                icon: Icons.account_circle_outlined,
                title: l10n.hideAiAssistantAvatarTitle,
                subtitle: l10n.hideAiAssistantAvatarSubtitle,
                value: themeVm.ui.hideAiAssistantAvatar,
                showDivider: false,
                onChanged: themeVm.updateHideAiAssistantAvatar,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const LlmSettingsContent(),
      ],
    );
  }
}
