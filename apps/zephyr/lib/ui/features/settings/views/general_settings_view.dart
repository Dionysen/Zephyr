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
    this.showDesktopBehaviorSettings = false,
  });

  final ThemeViewModel viewModel;
  final bool compact;

  /// Immersive / hide-icons toggles only apply on mobile shells.
  final bool showStatusBarSettings;

  /// Compact-editor behavior toggles (mobile settings only).
  final bool showMobileBehaviorSettings;

  /// Workspace chrome toggles (desktop settings panel only).
  final bool showDesktopBehaviorSettings;

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
            for (final option in AppLocalePreference.selectable)
              ZephyrSettingsChoice(
                value: option,
                label: _localeLabel(l10n, option),
              ),
          ],
          onSelected: viewModel.updateLocalePreference,
        ),
        ZephyrSettingsSwitchTile(
          icon: Icons.notes_outlined,
          title: l10n.showChapterDetailsTitle,
          subtitle: l10n.showChapterDetailsSubtitle,
          value: viewModel.ui.showChapterDetails,
          showDivider:
              showStatusBarSettings ||
              showMobileBehaviorSettings ||
              showDesktopBehaviorSettings,
          onChanged: viewModel.updateShowChapterDetails,
        ),
      ];
      final desktopChildren = showDesktopBehaviorSettings
          ? <Widget>[
              ZephyrSettingsSwitchTile(
                icon: Icons.view_sidebar_outlined,
                title: l10n.desktopFloatingSidebarTitle,
                subtitle: l10n.desktopFloatingSidebarSubtitle,
                value: viewModel.ui.desktopFloatingSidebar,
                onChanged: viewModel.updateDesktopFloatingSidebar,
              ),
              ZephyrSettingsSwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: l10n.desktopFloatingAiPanelTitle,
                subtitle: l10n.desktopFloatingAiPanelSubtitle,
                value: viewModel.ui.desktopFloatingAiPanel,
                showDivider: false,
                onChanged: viewModel.updateDesktopFloatingAiPanel,
              ),
            ]
          : const <Widget>[];
      final mobileChildren = showMobileBehaviorSettings
          ? <Widget>[
          ZephyrSettingsSwitchTile(
            icon: Icons.keyboard_hide_outlined,
            title: l10n.hideQuickToolbarTitle,
            subtitle: l10n.hideQuickToolbarSubtitle,
            value: viewModel.ui.hideQuickToolbar,
            onChanged: viewModel.updateHideQuickToolbar,
          ),
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
            showDivider: false,
            onChanged: viewModel.updateOpenSidebarOnStartup,
          ),
        ]
          : const <Widget>[];
      final statusChildren = showStatusBarSettings
          ? <Widget>[
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
        ]
          : const <Widget>[];

      if (compact) {
        return ZephyrSettingsSection(
          children: [
            ...coreChildren,
            ...desktopChildren,
            ...mobileChildren,
            ...statusChildren,
          ],
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        children: [
          Text(
            l10n.generalSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ZephyrSettingsSection(children: coreChildren),
          if (desktopChildren.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              l10n.desktopBehaviorSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.desktopBehaviorSectionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ZephyrSettingsSection(children: desktopChildren),
          ],
          if (mobileChildren.isNotEmpty) ...[
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
            const SizedBox(height: 12),
            ZephyrSettingsSection(children: mobileChildren),
          ],
          if (statusChildren.isNotEmpty) ...[
            const SizedBox(height: 24),
            ZephyrSettingsSection(children: statusChildren),
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
      AppLocalePreference.chineseTraditional => l10n.languageChineseTraditional,
      AppLocalePreference.english => l10n.languageEnglish,
      AppLocalePreference.japanese => l10n.languageJapanese,
      AppLocalePreference.korean => l10n.languageKorean,
      AppLocalePreference.spanish => l10n.languageSpanish,
      AppLocalePreference.french => l10n.languageFrench,
      AppLocalePreference.german => l10n.languageGerman,
      AppLocalePreference.portuguese => l10n.languagePortuguese,
      AppLocalePreference.russian => l10n.languageRussian,
      AppLocalePreference.arabic => l10n.languageArabic,
      AppLocalePreference.hindi => l10n.languageHindi,
      AppLocalePreference.italian => l10n.languageItalian,
    };
