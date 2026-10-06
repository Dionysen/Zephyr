import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/breakpoints.dart';
import '../../../core/zephyr_scope.dart';
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
  var _section = SettingsSection.theme;
  var _editingTokens = false;

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = ZephyrBreakpoints.isCompact(constraints.maxWidth);
            final content = _SettingsBody(
              onClose: () => Navigator.of(context).maybePop(),
              compact: compact,
              child: _buildSection(scope),
            );
            if (compact) {
              return Column(
                children: [
                  _CompactSettingsNavigation(
                    selected: _section,
                    onSelected: _select,
                  ),
                  const Divider(),
                  Expanded(child: content),
                ],
              );
            }
            return Row(
              children: [
                _SettingsNavigation(selected: _section, onSelected: _select),
                VerticalDivider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  void _select(SettingsSection section) {
    setState(() {
      _section = section;
      _editingTokens = false;
    });
    if (section == SettingsSection.editor) {
      unawaited(ZephyrScope.of(context).editorPreferences.loadSystemFonts());
    }
  }

  Widget _buildSection(ZephyrScope scope) => switch (_section) {
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
    _ => _SettingsPlaceholder(section: _section),
  };
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.child,
    required this.onClose,
    required this.compact,
  });

  final Widget child;
  final VoidCallback onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: compact
            ? const EdgeInsets.fromLTRB(24, 48, 24, 24)
            : const EdgeInsets.fromLTRB(56, 52, 56, 36),
        child: child,
      ),
      Positioned(
        top: 8,
        right: 8,
        child: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Close settings',
        ),
      ),
    ],
  );
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({required this.selected, required this.onSelected});

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
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
      ],
    ),
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
