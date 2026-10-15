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
    this.showMobileBehaviorSettings = false,
  });

  final ThemeViewModel viewModel;
  final bool compact;

  /// Immersive / hide-icons toggles only apply on mobile shells.
  final bool showStatusBarSettings;

  /// Compact-editor behavior toggles (mobile settings only).
  final bool showMobileBehaviorSettings;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final immersive = viewModel.ui.immersiveStatusBar;
      final locale = viewModel.ui.localePreference;
      final coreChildren = <Widget>[
        ZephyrSettingsChoiceTile<AppLocalePreference>(
          icon: Icons.language,
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
          icon: Icons.keyboard_hide_outlined,
          title: l10n.hideQuickToolbarTitle,
          subtitle: l10n.hideQuickToolbarSubtitle,
          value: viewModel.ui.hideQuickToolbar,
          onChanged: viewModel.updateHideQuickToolbar,
        ),
        ZephyrSettingsSwitchTile(
          icon: Icons.notes_outlined,
          title: l10n.showChapterDetailsTitle,
          subtitle: l10n.showChapterDetailsSubtitle,
          value: viewModel.ui.showChapterDetails,
          showDivider: showMobileBehaviorSettings || showStatusBarSettings,
          onChanged: viewModel.updateShowChapterDetails,
        ),
        if (showMobileBehaviorSettings) ...[
          ZephyrSettingsSwitchTile(
            icon: Icons.vertical_align_top_outlined,
            title: l10n.scrollToHideMobileTopBarTitle,
            subtitle: l10n.scrollToHideMobileTopBarSubtitle,
            value: viewModel.ui.scrollToHideMobileTopBar,
            onChanged: viewModel.updateScrollToHideMobileTopBar,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.menu_open_rounded,
            title: l10n.openSidebarAfterBookSwitchTitle,
            subtitle: l10n.openSidebarAfterBookSwitchSubtitle,
            value: viewModel.ui.openSidebarAfterBookSwitch,
            onChanged: viewModel.updateOpenSidebarAfterBookSwitch,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.light_mode_outlined,
            title: l10n.keepScreenOnTitle,
            subtitle: l10n.keepScreenOnSubtitle,
            value: viewModel.ui.keepScreenOn,
            onChanged: viewModel.updateKeepScreenOn,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.reply_rounded,
            title: l10n.doubleBackToExitTitle,
            subtitle: l10n.doubleBackToExitSubtitle,
            value: viewModel.ui.doubleBackToExit,
            onChanged: viewModel.updateDoubleBackToExit,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.library_books_outlined,
            title: l10n.openBookListOnStartupTitle,
            subtitle: l10n.openBookListOnStartupSubtitle,
            value: viewModel.ui.openBookListOnStartup,
            onChanged: viewModel.updateOpenBookListOnStartup,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.list_alt_outlined,
            title: l10n.openSidebarOnStartupTitle,
            subtitle: l10n.openSidebarOnStartupSubtitle,
            value: viewModel.ui.openSidebarOnStartup,
            showDivider: showStatusBarSettings,
            onChanged: viewModel.updateOpenSidebarOnStartup,
          ),
        ],
        if (showStatusBarSettings) ...[
          ZephyrSettingsSwitchTile(
            icon: Icons.fullscreen,
            title: l10n.immersiveStatusBarTitle,
            subtitle: l10n.immersiveStatusBarSubtitle,
            value: immersive,
            onChanged: viewModel.updateImmersiveStatusBar,
          ),
          ZephyrSettingsSwitchTile(
            icon: Icons.visibility_off_outlined,
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
          if (showMobileBehaviorSettings) ...[
            const SizedBox(height: 24),
            Text(
              l10n.mobileBehaviorSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mobileBehaviorSectionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
