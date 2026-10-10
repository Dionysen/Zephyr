import 'package:flutter/material.dart';

import '../../../../domain/models/ui_preferences.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../view_models/theme_view_model.dart';

class GeneralSettingsView extends StatelessWidget {
  const GeneralSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
    this.showStatusBarSettings = true,
  });

  final ThemeViewModel viewModel;
  final bool compact;

  /// Immersive / hide-icons toggles only apply on mobile shells.
  final bool showStatusBarSettings;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final immersive = viewModel.ui.immersiveStatusBar;
      final locale = viewModel.ui.localePreference;
      final children = <Widget>[
        ZephyrSettingsChoiceTile<AppLocalePreference>(
          title: l10n.languageTitle,
          subtitle: l10n.languageSubtitle,
          selected: locale,
          valueLabel: _localeLabel(l10n, locale),
          choices: [
            ZephyrSettingsChoice(
              value: AppLocalePreference.system,
              label: l10n.languageSystem,
            ),
            ZephyrSettingsChoice(
              value: AppLocalePreference.chinese,
              label: l10n.languageChinese,
            ),
            ZephyrSettingsChoice(
              value: AppLocalePreference.english,
              label: l10n.languageEnglish,
            ),
          ],
          onSelected: viewModel.updateLocalePreference,
        ),
        ZephyrSettingsSwitchTile(
          title: l10n.hideQuickToolbarTitle,
          subtitle: l10n.hideQuickToolbarSubtitle,
          value: viewModel.ui.hideQuickToolbar,
          showDivider: showStatusBarSettings,
          onChanged: viewModel.updateHideQuickToolbar,
        ),
        if (showStatusBarSettings) ...[
          ZephyrSettingsSwitchTile(
            title: l10n.immersiveStatusBarTitle,
            subtitle: l10n.immersiveStatusBarSubtitle,
            value: immersive,
            onChanged: viewModel.updateImmersiveStatusBar,
          ),
          ZephyrSettingsSwitchTile(
            title: l10n.hideStatusBarIconsTitle,
            subtitle: l10n.hideStatusBarIconsSubtitle,
            value: viewModel.ui.hideStatusBarIcons,
            showDivider: false,
            onChanged: immersive ? viewModel.updateHideStatusBarIcons : null,
          ),
        ],
      ];

      if (compact) {
        return ZephyrSettingsSection(children: children);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        children: [
          Text(
            l10n.generalSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ZephyrSettingsSection(children: children),
        ],
      );
    },
  );
}

String _localeLabel(AppLocalizations l10n, AppLocalePreference preference) =>
    switch (preference) {
      AppLocalePreference.system => l10n.languageSystem,
      AppLocalePreference.chinese => l10n.languageChinese,
      AppLocalePreference.english => l10n.languageEnglish,
    };
