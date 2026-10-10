import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_theme.dart';
import '../models/settings_section.dart';
import 'about_settings_view.dart';
import 'editor_settings_view.dart';
import 'general_settings_view.dart';
import 'shortcuts_settings_view.dart';
import 'theme_settings_view.dart';

/// Compact full-page settings route (mobile / narrow layouts).
///
/// Wide desktop layouts open [WorkspaceSettingsPanel] instead.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final scope = ZephyrScope.of(context);
      unawaited(scope.editorPreferences.loadSystemFonts());
      unawaited(scope.theme.loadSystemFonts());
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return ListenableBuilder(
      listenable: scope.theme,
      builder: (context, _) {
        final l10n = context.l10n;
        final immersiveStatusBar = scope.theme.ui.immersiveStatusBar;
        final hideStatusBarIcons = scope.theme.ui.hideStatusBarIcons;
        final barColor = ZephyrSettingsAppBar.backgroundColor(context);
        final surface = Theme.of(context).colorScheme.surface;
        return Theme(
          data: withMobileRoundControls(Theme.of(context)),
          child: ZephyrStatusBar(
            immersive: immersiveStatusBar,
            hideIcons: hideStatusBarIcons,
            statusBarColor: immersiveStatusBar ? surface : barColor,
            child: Scaffold(
              backgroundColor: surface,
              body: ColoredBox(
                color: surface,
                child: Column(
                  children: [
                    ColoredBox(
                      // Status bar band shows app-bar chrome color.
                      color: barColor,
                      child: ZephyrTopSafeArea(
                        bottom: false,
                        child: ZephyrSettingsAppBar(
                          title: l10n.settingsTitle,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: CompactSettingsList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Single scroll of every settings category; icons/titles act as dividers.
class CompactSettingsList extends StatelessWidget {
  const CompactSettingsList({
    super.key,
    this.showStatusBarSettings = true,
  });

  /// When false, omits immersive / hide-icons toggles (desktop panel).
  final bool showStatusBarSettings;

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        for (final section in SettingsSection.values) ...[
          ZephyrSettingsCategoryHeader(
            icon: section.icon,
            title: section.title(l10n),
          ),
          switch (section) {
            SettingsSection.general => GeneralSettingsView(
              viewModel: scope.theme,
              compact: true,
              showStatusBarSettings: showStatusBarSettings,
            ),
            SettingsSection.theme => ThemeCatalog(
              viewModel: scope.theme,
              compact: true,
            ),
            SettingsSection.editor => EditorSettingsView(
              viewModel: scope.editorPreferences,
              compact: true,
            ),
            SettingsSection.shortcuts => ShortcutsSettingsView(
              viewModel: scope.keyboardShortcuts,
              compact: true,
            ),
            SettingsSection.about => const AboutSettingsView(compact: true),
            _ => ZephyrSettingsSection(
              children: [
                ZephyrSettingsListTile(
                  title: l10n.settingsComingSoonTitle,
                  subtitle: l10n.settingsComingSoonSubtitle,
                  showDivider: false,
                ),
              ],
            ),
          },
        ],
      ],
    );
  }
}
