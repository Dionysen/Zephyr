import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/nested_back_navigator.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_theme.dart';
import '../models/settings_section.dart';
import '../models/settings_tab.dart';
import 'about_settings_view.dart';
import 'backup_settings_view.dart';
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

/// Tabbed settings body with a Material [NavigationBar] at the bottom.
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
    final settings = scope.settings;
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final tab = settings.tab;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: _pageChildren(
                  context,
                  tab: tab,
                  showStatusBarSettings: showStatusBarSettings,
                ),
              ),
            ),
            // NavigationBar's SafeArea also applies top view padding; when the
            // bar sits in a Column (not Scaffold.bottomNavigationBar) that
            // leaves a large empty band above the destinations.
            MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: NavigationBar(
                height: 78,
                selectedIndex: tab.index,
                onDestinationSelected: (index) {
                  settings.selectTab(SettingsTab.values[index]);
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final item in SettingsTab.values)
                    NavigationDestination(
                      key: ValueKey('settings-tab-${item.name}'),
                      icon: Icon(item.icon, size: 22),
                      label: item.title(l10n),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _pageChildren(
    BuildContext context, {
    required SettingsTab tab,
    required bool showStatusBarSettings,
  }) {
    final scope = ZephyrScope.of(context);
    final l10n = context.l10n;
    return switch (tab) {
      SettingsTab.general => [
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.general.icon,
          title: SettingsSection.general.title(l10n),
        ),
        GeneralSettingsView(
          viewModel: scope.theme,
          compact: true,
          showStatusBarSettings: showStatusBarSettings,
        ),
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.cloud.icon,
          title: SettingsSection.cloud.title(l10n),
        ),
        BackupSettingsView(
          viewModel: scope.backup,
          compact: true,
        ),
      ],
      SettingsTab.editor => [
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.editor.icon,
          title: SettingsSection.editor.title(l10n),
        ),
        EditorSettingsView(
          viewModel: scope.editorPreferences,
          compact: true,
        ),
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.shortcuts.icon,
          title: SettingsSection.shortcuts.title(l10n),
        ),
        ZephyrSettingsSection(
          children: [
            ZephyrSettingsListTile(
              icon: Icons.keyboard_alt_outlined,
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
      ],
      SettingsTab.appearance => [
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.theme.icon,
          title: SettingsSection.theme.title(l10n),
        ),
        ThemeCatalog(
          viewModel: scope.theme,
          compact: true,
        ),
      ],
      SettingsTab.about => [
        ZephyrSettingsCategoryHeader(
          icon: SettingsSection.about.icon,
          title: SettingsSection.about.title(l10n),
        ),
        const AboutSettingsView(compact: true),
      ],
    };
  }
}
