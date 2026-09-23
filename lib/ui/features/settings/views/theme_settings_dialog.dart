import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import '../view_models/theme_view_model.dart';

enum _SettingsPage { general, cloud, editor, shortcuts, theme, about }

class SettingsWindowPage extends StatefulWidget {
  const SettingsWindowPage({
    super.key,
    required this.viewModel,
    required this.editorPreferencesViewModel,
    required this.onClose,
  });
  final ThemeViewModel viewModel;
  final EditorPreferencesViewModel editorPreferencesViewModel;
  final VoidCallback onClose;

  @override
  State<SettingsWindowPage> createState() => _SettingsWindowPageState();
}

class _SettingsWindowPageState extends State<SettingsWindowPage> {
  _SettingsPage _page = _SettingsPage.theme;
  bool _editingTokens = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        void selectPage(_SettingsPage page) {
          setState(() {
            _page = page;
            _editingTokens = false;
          });
          if (page == _SettingsPage.editor) {
            unawaited(widget.editorPreferencesViewModel.loadSystemFonts());
          }
        }

        final content = _SettingsContent(
          onClose: widget.onClose,
          child: _buildPage(),
        );
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              _CompactSettingsNavigation(
                selected: _page,
                onSelected: selectPage,
              ),
              const Divider(),
              Expanded(child: content),
            ],
          );
        }
        return Row(
          children: [
            _SettingsNavigation(selected: _page, onSelected: selectPage),
            VerticalDivider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: content),
          ],
        );
      },
    ),
  );

  Widget _buildPage() => switch (_page) {
    _SettingsPage.theme when _editingTokens => _ThemeTokenEditor(
      viewModel: widget.viewModel,
      onBack: () => setState(() => _editingTokens = false),
    ),
    _SettingsPage.theme => _ThemeCatalog(
      viewModel: widget.viewModel,
      onCustomize: () => setState(() => _editingTokens = true),
    ),
    _SettingsPage.editor => _EditorSettingsPage(
      viewModel: widget.editorPreferencesViewModel,
    ),
    _ => _SettingsPlaceholder(page: _page),
  };
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({required this.child, required this.onClose});
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      children: [
        Padding(
          padding: constraints.maxWidth < 760
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
    ),
  );
}

class _SettingsNavigation extends StatelessWidget {
  const _SettingsNavigation({required this.selected, required this.onSelected});
  final _SettingsPage selected;
  final ValueChanged<_SettingsPage> onSelected;

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
        for (final page in _SettingsPage.values)
          _SettingsNavigationItem(
            page: page,
            selected: page == selected,
            onTap: () => onSelected(page),
          ),
        const Spacer(),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const _ShortcutHint(label: 'Ctrl+F'),
              const SizedBox(width: 9),
              Text('Search', style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CompactSettingsNavigation extends StatelessWidget {
  const _CompactSettingsNavigation({
    required this.selected,
    required this.onSelected,
  });
  final _SettingsPage selected;
  final ValueChanged<_SettingsPage> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        for (final page in _SettingsPage.values)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: page == selected
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () => onSelected(page),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(_icon(page), size: 17),
                      const SizedBox(width: 6),
                      Text(_pageTitle(page)),
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
    required this.page,
    required this.selected,
    required this.onTap,
  });
  final _SettingsPage page;
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
              Icon(_icon(page), size: 19),
              const SizedBox(width: 12),
              Text(
                _pageTitle(page),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ThemeCatalog extends StatelessWidget {
  const _ThemeCatalog({required this.viewModel, required this.onCustomize});
  final ThemeViewModel viewModel;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final active = viewModel.tokens.preset;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Choose a theme, then customize its semantic tokens if needed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ModeChip(label: 'System', selected: false),
              _ModeChip(label: 'Light', selected: false),
              _ModeChip(label: 'Dark', selected: true),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            active == null
                ? 'Current theme: Custom'
                : 'Current theme: ${_presetTitle(active)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Theme presets apply to all writing-shell surfaces.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisExtent: 168,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: ThemePreset.values.length,
              itemBuilder: (context, index) {
                final preset = ThemePreset.values[index];
                return _ThemePresetCard(
                  preset: preset,
                  selected: preset == active,
                  onTap: () => viewModel.applyPreset(preset),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onCustomize,
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Customize tokens'),
            ),
          ),
        ],
      );
    },
  );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.presets[preset]!;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? Color(tokens.accent)
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemePreview(tokens: tokens),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _presetTitle(preset),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: Color(tokens.accent),
                      size: 18,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.tokens});
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: SizedBox(
      height: 82,
      child: Row(
        children: [
          Container(
            width: 64,
            color: Color(tokens.sidebarSurface),
            child: _PreviewLines(tokens: tokens, compact: true),
          ),
          Expanded(
            child: Container(
              color: Color(tokens.editorSurface),
              child: _PreviewLines(tokens: tokens),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewLines extends StatelessWidget {
  const _PreviewLines({required this.tokens, this.compact = false});
  final ThemeTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 24, height: 4, color: Color(tokens.accent)),
        const SizedBox(height: 8),
        for (final width in compact ? [30.0, 22.0, 26.0] : [86.0, 62.0, 78.0])
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Container(
              width: width,
              height: 4,
              color: Color(tokens.mutedText).withValues(alpha: .55),
            ),
          ),
      ],
    ),
  );
}

class _ThemeTokenEditor extends StatefulWidget {
  const _ThemeTokenEditor({required this.viewModel, required this.onBack});
  final ThemeViewModel viewModel;
  final VoidCallback onBack;

  @override
  State<_ThemeTokenEditor> createState() => _ThemeTokenEditorState();
}

class _ThemeTokenEditorState extends State<_ThemeTokenEditor> {
  late final Map<ThemeToken, TextEditingController> _controllers = {
    for (final token in ThemeToken.values)
      token: TextEditingController(
        text: _hex(widget.viewModel.tokens.valueOf(token)),
      ),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Back to themes'),
        ),
        const SizedBox(height: 8),
        Text('Theme tokens', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Use a six-digit hexadecimal color. Changes apply immediately.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView(
            children: [
              for (final token in ThemeToken.values)
                _TokenField(
                  label: _tokenLabel(token),
                  controller: _controllers[token]!,
                  value: widget.viewModel.tokens.valueOf(token),
                  onChanged: (value) => widget.viewModel.update(token, value),
                ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              widget.viewModel.restoreDefaults();
              for (final token in ThemeToken.values) {
                _controllers[token]!.text = _hex(
                  widget.viewModel.tokens.valueOf(token),
                );
              }
            },
            child: const Text('Restore Dark Modern defaults'),
          ),
        ),
      ],
    ),
  );
}

class _TokenField extends StatelessWidget {
  const _TokenField({
    required this.label,
    required this.controller,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Color(value),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 165, child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: 7,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '#RRGGBB',
            ),
            onChanged: (text) {
              final value = _parseHex(text);
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    ),
  );
}

class _EditorSettingsPage extends StatelessWidget {
  const _EditorSettingsPage({required this.viewModel});
  final EditorPreferencesViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final preferences = viewModel.preferences;
      final selectedFont = viewModel.systemFonts
          .where((font) => font.path == preferences.fontPath)
          .firstOrNull;
      return Scrollbar(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
          Text('Editor', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Typography and reading-column preferences apply immediately.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (viewModel.isLoadingSystemFonts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (viewModel.systemFonts.isEmpty)
            const Text(
              'No system fonts were found. The platform default will be used.',
            )
          else
            DropdownButtonFormField<SystemFont>(
              initialValue: selectedFont,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'System font'),
              hint: const Text('Platform default'),
              items: [
                const DropdownMenuItem<SystemFont>(
                  value: null,
                  child: Text('Platform default'),
                ),
                ...viewModel.systemFonts.map(
                  (font) =>
                      DropdownMenuItem(value: font, child: Text(font.family)),
                ),
              ],
              onChanged: viewModel.selectFont,
            ),
          const SizedBox(height: 18),
          _EditorSlider(
            label: 'Font size',
            value: preferences.fontSize,
            min: 12,
            max: 32,
            suffix: 'px',
            onChanged: viewModel.updateFontSize,
          ),
          _EditorSlider(
            label: 'Line height',
            value: preferences.lineHeight,
            min: 1.2,
            max: 2.4,
            suffix: '',
            onChanged: viewModel.updateLineHeight,
          ),
          _EditorSlider(
            label: 'Paragraph spacing',
            value: preferences.paragraphSpacing,
            min: 0,
            max: 32,
            suffix: 'px',
            onChanged: viewModel.updateParagraphSpacing,
          ),
          _EditorSlider(
            label: 'First-line indent',
            value: preferences.firstLineIndent.toDouble(),
            min: 0,
            max: 4,
            suffix: ' characters',
            divisions: 4,
            onChanged: (value) =>
                viewModel.updateFirstLineIndent(value.round()),
          ),
          _EditorSlider(
            label: 'Editor width',
            value: preferences.maxContentWidth,
            min: 480,
            max: 1200,
            suffix: 'px',
            onChanged: viewModel.updateMaxContentWidth,
          ),
          ],
        ),
      );
    },
  );
}

class _EditorSlider extends StatelessWidget {
  const _EditorSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
    this.divisions,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${value.toStringAsFixed(divisions == null ? 1 : 0)}$suffix',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder({required this.page});
  final _SettingsPage page;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(_pageTitle(page), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Text(
        'This settings section is reserved for its own feature settings.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _ShortcutHint extends StatelessWidget {
  const _ShortcutHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    ),
  );
}

String _pageTitle(_SettingsPage page) => switch (page) {
  _SettingsPage.general => 'General',
  _SettingsPage.cloud => 'Cloud sync',
  _SettingsPage.editor => 'Editor',
  _SettingsPage.shortcuts => 'Shortcuts',
  _SettingsPage.theme => 'Theme',
  _SettingsPage.about => 'About',
};

IconData _icon(_SettingsPage page) => switch (page) {
  _SettingsPage.general => Icons.tune,
  _SettingsPage.cloud => Icons.cloud_outlined,
  _SettingsPage.editor => Icons.edit_outlined,
  _SettingsPage.shortcuts => Icons.keyboard_outlined,
  _SettingsPage.theme => Icons.palette_outlined,
  _SettingsPage.about => Icons.info_outline,
};

String _presetTitle(ThemePreset preset) => switch (preset) {
  ThemePreset.light => 'Light',
  ThemePreset.grey => 'Grey',
  ThemePreset.slate => 'Slate',
  ThemePreset.claude => 'Claude Code',
  ThemePreset.mint => 'Mint',
  ThemePreset.purple => 'Purple',
  ThemePreset.hermes => 'Hermes',
  ThemePreset.ocean => 'Ocean',
  ThemePreset.darkModern => 'Dark Modern',
};

String _tokenLabel(ThemeToken token) => switch (token) {
  ThemeToken.editorSurface => 'Editor surface',
  ThemeToken.sidebarSurface => 'Sidebar surface',
  ThemeToken.controlSurface => 'Control surface',
  ThemeToken.border => 'Border',
  ThemeToken.primaryText => 'Primary text',
  ThemeToken.mutedText => 'Muted text',
  ThemeToken.accent => 'Accent',
};

String _hex(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _parseHex(String value) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  return match == null
      ? null
      : 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}
