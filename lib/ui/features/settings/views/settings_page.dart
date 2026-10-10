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

/// Tabbed settings body with a floating stadium tab bar at the bottom.
class CompactSettingsList extends StatelessWidget {
  const CompactSettingsList({
    super.key,
    this.showStatusBarSettings = true,
  });

  /// When false, omits immersive / hide-icons toggles (desktop panel).
  final bool showStatusBarSettings;

  static const _tabBarHeight = 64.0;
  static const _tabBarBottomGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    final settings = scope.settings;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final clearance = _tabBarHeight + _tabBarBottomGap + bottomSafe;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final tab = settings.tab;
        return Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + clearance),
                children: _pageChildren(
                  context,
                  tab: tab,
                  showStatusBarSettings: showStatusBarSettings,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: _tabBarBottomGap + bottomSafe,
              child: _SettingsFloatingTabBar(
                selected: tab,
                onSelected: settings.selectTab,
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

class _SettingsFloatingTabBar extends StatelessWidget {
  const _SettingsFloatingTabBar({
    required this.selected,
    required this.onSelected,
  });

  final SettingsTab selected;
  final ValueChanged<SettingsTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dark = theme.brightness == Brightness.dark;
    final barColor = (dark ? Colors.black : Colors.white).withValues(
      alpha: dark ? 0.82 : 0.92,
    );
    final shadow = theme.colorScheme.shadow;
    const shape = StadiumBorder();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: dark ? 0.45 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: shadow.withValues(alpha: dark ? 0.28 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: barColor,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        child: SizedBox(
          height: CompactSettingsList._tabBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              children: [
                for (final tab in SettingsTab.values)
                  Expanded(
                    child: _SettingsTabItem(
                      key: ValueKey('settings-tab-${tab.name}'),
                      icon: tab.icon,
                      label: tab.title(l10n),
                      selected: tab == selected,
                      onTap: () => onSelected(tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTabItem extends StatelessWidget {
  const _SettingsTabItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.72);
    final bg = selected ? scheme.primary : Colors.transparent;

    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontSize: 11,
                  height: 1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
