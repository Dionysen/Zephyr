import 'package:flutter/material.dart';

import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_theme.dart';
import '../view_models/theme_view_model.dart';

class ThemeCatalog extends StatelessWidget {
  const ThemeCatalog({
    super.key,
    required this.viewModel,
    required this.onCustomize,
  });

  final ThemeViewModel viewModel;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final active = viewModel.tokens.preset;
      final isLight =
          Color(viewModel.tokens.editorSurface).computeLuminance() > .5;
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
              _ModeChip(
                label: 'System',
                selected: false,
                onTap: () {
                  final dark =
                      MediaQuery.platformBrightnessOf(context) ==
                      Brightness.dark;
                  viewModel.applyPreset(
                    dark ? ThemePreset.darkModern : ThemePreset.light,
                  );
                },
              ),
              _ModeChip(
                label: 'Light',
                selected: isLight,
                onTap: () => viewModel.applyPreset(ThemePreset.light),
              ),
              _ModeChip(
                label: 'Dark',
                selected: !isLight,
                onTap: () => viewModel.applyPreset(ThemePreset.darkModern),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _UiFontRow(viewModel: viewModel),
          ZephyrSettingsSlider(
            label: 'UI font size',
            description: 'Size of sidebar, settings, and chrome text.',
            value: viewModel.ui.fontSize,
            min: 11,
            max: 18,
            suffix: 'px',
            onChanged: viewModel.updateUiFontSize,
          ),
          ZephyrSettingsSlider(
            label: 'Corner radius',
            description: 'Shared roundness for buttons, menus, cards, and fields.',
            value: viewModel.ui.cornerRadius,
            min: UiPreferences.minCornerRadius,
            max: UiPreferences.maxCornerRadius,
            suffix: 'px',
            onChanged: viewModel.updateCornerRadius,
          ),
          const SizedBox(height: 10),
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
              icon: const Icon(Icons.tune),
              label: const Text('Customize tokens'),
            ),
          ),
        ],
      );
    },
  );
}

class _UiFontRow extends StatelessWidget {
  const _UiFontRow({required this.viewModel});

  final ThemeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingSystemFonts) {
      return const ZephyrSettingsRow(
        label: 'UI font',
        description: 'Typeface used by the writing shell chrome.',
        child: LinearProgressIndicator(),
      );
    }
    if (viewModel.systemFonts.isEmpty) {
      return ZephyrSettingsRow(
        label: 'UI font',
        description: 'Typeface used by the writing shell chrome.',
        child: Text(
          'Platform default',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final fonts = viewModel.systemFonts;
    final selectedPath = viewModel.ui.fontPath ?? '';
    return ZephyrSettingsRow(
      label: 'UI font',
      description: 'Typeface used by the writing shell chrome.',
      child: ZephyrDropdown<String>(
        value: selectedPath,
        hint: 'Platform default',
        items: [
          const ZephyrDropdownItem(value: '', label: 'Platform default'),
          for (final font in fonts)
            ZephyrDropdownItem(value: font.path, label: font.family),
        ],
        onChanged: (path) {
          if (path.isEmpty) {
            viewModel.selectUiFont(null);
            return;
          }
          final font = fonts.where((item) => item.path == path).firstOrNull;
          if (font != null) {
            viewModel.selectUiFont(font);
          }
        },
      ),
    );
  }
}

class ThemeTokenEditor extends StatefulWidget {
  const ThemeTokenEditor({
    super.key,
    required this.viewModel,
    required this.onBack,
  });

  final ThemeViewModel viewModel;
  final VoidCallback onBack;

  @override
  State<ThemeTokenEditor> createState() => _ThemeTokenEditorState();
}

class _ThemeTokenEditorState extends State<ThemeTokenEditor> {
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
          icon: const Icon(Icons.arrow_back),
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
                  description: _tokenDescription(token),
                  controller: _controllers[token]!,
                  value: widget.viewModel.tokens.valueOf(token),
                  onChanged: (value) => widget.viewModel.update(token, value),
                  showDivider: token != ThemeToken.values.last,
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: context.zephyrBorderRadius,
      child: InkWell(
        borderRadius: context.zephyrBorderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
    ),
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
    final radius = context.zephyrBorderRadius;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: selected
              ? Color(tokens.accent)
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
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
    borderRadius: context.zephyrBorderRadius,
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

class _TokenField extends StatelessWidget {
  const _TokenField({
    required this.label,
    required this.description,
    required this.controller,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  final String label;
  final String description;
  final TextEditingController controller;
  final int value;
  final ValueChanged<int> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => ZephyrSettingsRow(
    label: label,
    description: description,
    showDivider: showDivider,
    child: Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Color(value),
            borderRadius: context.zephyrBorderRadius,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: 7,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '#RRGGBB',
            ),
            onChanged: (text) {
              final parsed = _parseHex(text);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ],
    ),
  );
}

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

String _tokenDescription(ThemeToken token) => switch (token) {
  ThemeToken.editorSurface => 'Background of the writing column.',
  ThemeToken.sidebarSurface => 'Background of side panels and chrome.',
  ThemeToken.controlSurface => 'Fill color for fields, menus, and cards.',
  ThemeToken.border => 'Hairlines around controls and dividers.',
  ThemeToken.primaryText => 'Default title and body copy color.',
  ThemeToken.mutedText => 'Dimmer copy used for setting hints and captions.',
  ThemeToken.accent => 'Interactive highlights and selected states.',
};

String _hex(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _parseHex(String value) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  return match == null
      ? null
      : 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}
