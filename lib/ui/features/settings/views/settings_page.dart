import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/nested_back_navigator.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_theme.dart';
import '../models/settings_section.dart';
import 'about_settings_view.dart';
import 'editor_settings_view.dart';
import 'general_settings_view.dart';
import 'shortcuts_settings_page.dart';
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
        final immersiveStatusBar = scope.theme.ui.immersiveStatusBar;
        final hideStatusBarIcons = scope.theme.ui.hideStatusBarIcons;
        final surface = Theme.of(context).colorScheme.surface;
        final barColor = ZephyrSettingsAppBar.backgroundColor(context);
        return Theme(
          data: withMobileRoundControls(Theme.of(context)),
          child: ZephyrStatusBar(
            immersive: immersiveStatusBar,
            hideIcons: hideStatusBarIcons,
            statusBarColor: immersiveStatusBar ? surface : barColor,
            child: Scaffold(
              backgroundColor: surface,
              // Nested navigator + PopScope: gesture back pops sub-pages /
              // sheets before leaving settings.
              body: NestedBackNavigator(
                onGenerateRoute: (settings) {
                  return MaterialPageRoute<void>(
                    settings: settings,
                    builder: (_) => const _SettingsHome(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsHome extends StatelessWidget {
  const _SettingsHome();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final surface = Theme.of(context).colorScheme.surface;
    final barColor = ZephyrSettingsAppBar.backgroundColor(context);
    return ColoredBox(
      color: surface,
      child: Column(
        children: [
          ColoredBox(
            color: barColor,
            child: ZephyrTopSafeArea(
              bottom: false,
              child: ZephyrSettingsAppBar(
                title: l10n.settingsTitle,
                onBack: () => Navigator.of(context, rootNavigator: true).maybePop(),
              ),
            ),
          ),
          const Expanded(
            child: CompactSettingsList(),
          ),
        ],
      ),
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
            SettingsSection.shortcuts => ZephyrSettingsSection(
              children: [
                ZephyrSettingsListTile(
                  title: l10n.shortcutsManageTitle,
                  subtitle: l10n.shortcutsManageSubtitle,
                  showDivider: false,
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.of(context).push(ShortcutsSettingsPage.route());
                  },
                ),
              ],
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
