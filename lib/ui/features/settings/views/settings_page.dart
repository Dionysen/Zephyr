import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/settings_navigation.dart';
import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_resize_handle.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_theme.dart';
import '../../workspace/views/workspace_sidebar.dart';
import '../models/settings_section.dart';
import 'editor_settings_view.dart';
import 'general_settings_view.dart';
import 'theme_settings_view.dart';

/// Settings is a normal route on every platform so appearance stays live
/// against the same view models as the writing workspace.
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
      listenable: Listenable.merge([scope.settings, scope.theme]),
      builder: (context, _) {
        final l10n = context.l10n;
        final section = scope.settings.section;
        final immersiveStatusBar = scope.theme.ui.immersiveStatusBar;
        final hideStatusBarIcons = scope.theme.ui.hideStatusBarIcons;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = ZephyrBreakpoints.isCompact(
              constraints.maxWidth,
            );
            final maxSidebarWidth = _maxSidebarWidth(constraints.maxWidth);
            final sidebarWidth = scope.settings.sidebarWidth.clamp(
              SettingsNavigation.minSidebarWidth,
              maxSidebarWidth,
            );
            if (compact) {
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
                                onBack: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _CompactSettingsList(scope: scope),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            final content = _SettingsBody(
              compact: false,
              child: _buildDesktopSection(scope, section),
            );
            final desktopSurface = Theme.of(context).colorScheme.surface;
            return ZephyrStatusBar(
              immersive: immersiveStatusBar,
              hideIcons: hideStatusBarIcons,
              statusBarColor: desktopSurface,
              child: Scaffold(
                backgroundColor: desktopSurface,
                body: WindowChrome.isDesktop
                    ? SafeArea(
                        top: false,
                        child: _desktopSettingsRow(
                          scope: scope,
                          section: section,
                          sidebarWidth: sidebarWidth,
                          maxSidebarWidth: maxSidebarWidth,
                          content: content,
                        ),
                      )
                    : ZephyrTopSafeArea(
                        child: _desktopSettingsRow(
                          scope: scope,
                          section: section,
                          sidebarWidth: sidebarWidth,
                          maxSidebarWidth: maxSidebarWidth,
                          content: content,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _desktopSettingsRow({
    required ZephyrScope scope,
    required SettingsSection section,
    required double sidebarWidth,
    required double maxSidebarWidth,
    required Widget content,
  }) => Row(
    children: [
      SizedBox(
        width: sidebarWidth,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: _SettingsNavigation(
            selected: section,
            onSelected: _select,
            onBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      ZephyrResizeHandle(
        onDragStart: () => scope.settings.setSidebarResizing(true),
        onDragUpdate: (delta) => scope.settings.resizeSidebar(
          (sidebarWidth + delta).clamp(
            SettingsNavigation.minSidebarWidth,
            maxSidebarWidth,
          ),
        ),
        onDragEnd: () => scope.settings.setSidebarResizing(false),
        onDragCancel: () => scope.settings.setSidebarResizing(false),
      ),
      Expanded(
        child: Column(
          children: [
            const _DesktopSettingsHeader(),
            Expanded(child: content),
          ],
        ),
      ),
    ],
  );

  void _select(SettingsSection section) {
    final scope = ZephyrScope.of(context);
    scope.settings.select(section);
    switch (section) {
      case SettingsSection.editor:
        unawaited(scope.editorPreferences.loadSystemFonts());
      case SettingsSection.theme:
        unawaited(scope.theme.loadSystemFonts());
      case _:
        break;
    }
  }

  Widget _buildDesktopSection(ZephyrScope scope, SettingsSection section) =>
      switch (section) {
        SettingsSection.general => GeneralSettingsView(
          viewModel: scope.theme,
        ),
        SettingsSection.theme => ThemeCatalog(
          viewModel: scope.theme,
        ),
        SettingsSection.editor => EditorSettingsView(
          viewModel: scope.editorPreferences,
        ),
        _ => _SettingsPlaceholder(section: section),
      };

  double _maxSidebarWidth(double pageWidth) =>
      (pageWidth - 480 - ZephyrResizeHandle.width).clamp(
        SettingsNavigation.minSidebarWidth,
        SettingsNavigation.maxSidebarWidth,
      );
}

/// Single scroll of every settings category; icons/titles act as dividers.
class _CompactSettingsList extends StatelessWidget {
  const _CompactSettingsList({required this.scope});

  final ZephyrScope scope;

  @override
  Widget build(BuildContext context) {
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
            ),
            SettingsSection.theme => ThemeCatalog(
              viewModel: scope.theme,
              compact: true,
            ),
            SettingsSection.editor => EditorSettingsView(
              viewModel: scope.editorPreferences,
              compact: true,
            ),
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

class _DesktopSettingsHeader extends StatelessWidget {
  const _DesktopSettingsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: WorkspaceHeader.height,
        child: Stack(
          children: [
            const Row(
              children: [
                Expanded(child: WindowDragArea(child: SizedBox.expand())),
                WindowCaptionButtons(),
              ],
            ),
            IgnorePointer(
              child: Center(
                child: Text(
                  l10n.settingsDesktopHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.child, required this.compact});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: compact
        ? const EdgeInsets.fromLTRB(16, 12, 16, 24)
        : const EdgeInsets.fromLTRB(56, 20, 56, 36),
    child: child,
  );
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({
    required this.selected,
    required this.onSelected,
    required this.onBack,
  });

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
    children: [
      SizedBox(
        height: WorkspaceHeader.height,
        child: Row(
          children: [
            if (WindowChrome.leadingChromeInset > 0)
              SizedBox(width: WindowChrome.leadingChromeInset),
            const Expanded(child: WindowDragArea(child: SizedBox.expand())),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, size: 19),
            hintText: l10n.settingsSearchHint,
          ),
        ),
      ),
      for (final section in SettingsSection.values)
        _SettingsNavigationItem(
          section: section,
          selected: section == selected,
          onTap: () => onSelected(section),
        ),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.actionBack),
          ),
        ),
      ),
    ],
  );
  }
}

class _SettingsNavigationItem extends StatelessWidget {
  const _SettingsNavigationItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: context.zephyrBorderRadius,
      child: InkWell(
        borderRadius: context.zephyrBorderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(section.icon, size: 19),
              const SizedBox(width: 12),
              Text(
                section.title(l10n),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(section.title(l10n), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Text(
        l10n.settingsPlaceholderBody,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
  }
}
