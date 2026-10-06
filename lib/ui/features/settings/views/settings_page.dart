import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/settings_navigation.dart';
import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_resize_handle.dart';
import '../../../core/zephyr_scope.dart';
import '../../workspace/views/workspace_sidebar.dart';
import '../models/settings_section.dart';
import 'editor_settings_view.dart';
import 'theme_settings_view.dart';

/// Settings is a normal route on every platform so appearance stays live
/// against the same view models as the writing workspace.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _editingTokens = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureEditorFonts(ZephyrScope.of(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (context, _) {
        final section = scope.settings.section;
        return Scaffold(
          body: SafeArea(
            top: !WindowChrome.isDesktop,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = ZephyrBreakpoints.isCompact(
                  constraints.maxWidth,
                );
                final maxSidebarWidth = _maxSidebarWidth(constraints.maxWidth);
                final sidebarWidth = scope.settings.sidebarWidth.clamp(
                  SettingsNavigation.minSidebarWidth,
                  maxSidebarWidth,
                );
                final content = _SettingsBody(
                  compact: compact,
                  child: _buildSection(scope, section),
                );
                if (compact) {
                  return Column(
                    children: [
                      const _SettingsHeader(),
                      _CompactSettingsNavigation(
                        selected: section,
                        onSelected: _select,
                      ),
                      const Divider(),
                      Expanded(child: content),
                      _SettingsBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(
                      width: sidebarWidth,
                      child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
                        child: _SettingsNavigation(
                          selected: section,
                          onSelected: _select,
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    ),
                    ZephyrResizeHandle(
                      onDragStart: () =>
                          scope.settings.setSidebarResizing(true),
                      onDragUpdate: (delta) => scope.settings.resizeSidebar(
                        (sidebarWidth + delta).clamp(
                          SettingsNavigation.minSidebarWidth,
                          maxSidebarWidth,
                        ),
                      ),
                      onDragEnd: () => scope.settings.setSidebarResizing(false),
                      onDragCancel: () =>
                          scope.settings.setSidebarResizing(false),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const _SettingsHeader(),
                          Expanded(child: content),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _select(SettingsSection section) {
    setState(() => _editingTokens = false);
    final scope = ZephyrScope.of(context);
    scope.settings.select(section);
    _ensureEditorFonts(scope);
  }

  void _ensureEditorFonts(ZephyrScope scope) {
    if (scope.settings.section == SettingsSection.editor) {
      unawaited(scope.editorPreferences.loadSystemFonts());
    }
  }

  Widget _buildSection(ZephyrScope scope, SettingsSection section) =>
      switch (section) {
        SettingsSection.theme when _editingTokens => ThemeTokenEditor(
          viewModel: scope.theme,
          onBack: () => setState(() => _editingTokens = false),
        ),
        SettingsSection.theme => ThemeCatalog(
          viewModel: scope.theme,
          onCustomize: () => setState(() => _editingTokens = true),
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

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  'Settings',
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
        ? const EdgeInsets.fromLTRB(24, 16, 24, 24)
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
  Widget build(BuildContext context) => Column(
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
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, size: 19),
            hintText: 'Search settings',
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
      _SettingsBackButton(onPressed: onBack),
    ],
  );
}

class _CompactSettingsNavigation extends StatelessWidget {
  const _CompactSettingsNavigation({
    required this.selected,
    required this.onSelected,
  });

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        for (final section in SettingsSection.values)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: section == selected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () => onSelected(section),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(section.icon, size: 17),
                      const SizedBox(width: 6),
                      Text(section.title),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(section.icon, size: 19),
              const SizedBox(width: 12),
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
    child: SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back'),
      ),
    ),
  );
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(section.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Text(
        'This settings section is reserved for its own feature settings.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
