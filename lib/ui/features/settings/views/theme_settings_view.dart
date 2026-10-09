import 'package:flutter/material.dart';

import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_theme.dart';
import '../view_models/theme_view_model.dart';
import 'font_file_picker.dart';

class ThemeCatalog extends StatelessWidget {
  const ThemeCatalog({
    super.key,
    required this.viewModel,
    required this.onCustomize,
    this.compact = false,
  });

  final ThemeViewModel viewModel;
  final VoidCallback onCustomize;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final active = viewModel.tokens.preset;
      final isLight =
          Color(viewModel.tokens.editorSurface).computeLuminance() > .5;
      final defaults = UiPreferences.defaults;

      if (compact) {
        // Non-scrollable fragment; the parent settings page owns scrolling.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsChoiceTile<String>(
                  title: l10n.themeModeTitle,
                  subtitle: l10n.themeModeSubtitle,
                  selected: isLight ? 'light' : 'dark',
                  choices: [
                    ZephyrSettingsChoice(
                      value: 'system',
                      label: l10n.themeModeSystem,
                    ),
                    ZephyrSettingsChoice(
                      value: 'light',
                      label: l10n.themeModeLight,
                    ),
                    ZephyrSettingsChoice(
                      value: 'dark',
                      label: l10n.themeModeDark,
                    ),
                  ],
                  valueLabel:
                      isLight ? l10n.themeModeLight : l10n.themeModeDark,
                  onSelected: (mode) {
                    if (mode == 'system') {
                      final dark = MediaQuery.platformBrightnessOf(context) ==
                          Brightness.dark;
                      viewModel.applyPreset(
                        dark ? ThemePreset.darkModern : ThemePreset.light,
                      );
                      return;
                    }
                    viewModel.applyPreset(
                      mode == 'light'
                          ? ThemePreset.light
                          : ThemePreset.darkModern,
                    );
                  },
                ),
                FontFilePickerRow(
                  label: l10n.uiFontLabel,
                  description: l10n.uiFontDescription,
                  fonts: viewModel.systemFonts,
                  selectedPath: viewModel.ui.fontPath,
                  isLoading: viewModel.isLoadingSystemFonts,
                  onSelected: viewModel.selectUiFont,
                  onImportPath: viewModel.importUiFontFromPath,
                  onDeleteFont: viewModel.deleteImportedFont,
                  compact: true,
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  title: l10n.uiFontSizeTitle,
                  description: l10n.uiFontSizeDescription,
                  value: viewModel.ui.fontSize,
                  min: 11,
                  max: 18,
                  defaultValue: defaults.fontSize,
                  suffix: 'px',
                  divisions: 7,
                  onChanged: viewModel.updateUiFontSize,
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  title: l10n.cornerRadiusTitle,
                  description: l10n.cornerRadiusDescription,
                  value: viewModel.ui.cornerRadius,
                  min: UiPreferences.minCornerRadius,
                  max: UiPreferences.maxCornerRadius,
                  defaultValue: defaults.cornerRadius,
                  suffix: 'px',
                  divisions: 20,
                  onChanged: viewModel.updateCornerRadius,
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  title: l10n.barCornerRadiusTitle,
                  description: l10n.barCornerRadiusDescription,
                  value: viewModel.ui.barCornerRadius,
                  min: UiPreferences.minBarCornerRadius,
                  max: UiPreferences.maxBarCornerRadius,
                  defaultValue: defaults.barCornerRadius,
                  suffix: 'px',
                  divisions: 24,
                  onChanged: viewModel.updateBarCornerRadius,
                ),
                ZephyrSettingsSwitchTile(
                  title: l10n.showBordersTitle,
                  subtitle: l10n.showBordersSubtitle,
                  value: viewModel.ui.showBorders,
                  onChanged: viewModel.updateShowBorders,
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  title: l10n.sidebarItemInsetTitle,
                  description: l10n.sidebarItemInsetDescription,
                  value: viewModel.ui.sidebarItemInset,
                  min: UiPreferences.minSidebarItemInset,
                  max: UiPreferences.maxSidebarItemInset,
                  defaultValue: defaults.sidebarItemInset,
                  suffix: 'px',
                  divisions: 24,
                  onChanged: viewModel.updateSidebarItemInset,
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  title: l10n.sidebarVolumeGapTitle,
                  description: l10n.sidebarVolumeGapDescription,
                  value: viewModel.ui.sidebarVolumeGap,
                  min: UiPreferences.minSidebarVolumeGap,
                  max: UiPreferences.maxSidebarVolumeGap,
                  defaultValue: defaults.sidebarVolumeGap,
                  suffix: 'px',
                  divisions: 9,
                  showDivider: false,
                  onChanged: viewModel.updateSidebarVolumeGap,
                ),
              ],
            ),
            ZephyrSettingsSection(
              title: l10n.themePresetsSectionTitle,
              footer: active == null
                  ? l10n.themeCurrentCustom
                  : l10n.themeCurrentPreset(_presetTitle(l10n, active)),
              children: [
                for (var i = 0; i < ThemePreset.values.length; i++)
                  ZephyrSettingsListTile(
                    title: _presetTitle(l10n, ThemePreset.values[i]),
                    showDivider: i != ThemePreset.values.length - 1,
                    trailing: ThemePreset.values[i] == active
                        ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () =>
                        viewModel.applyPreset(ThemePreset.values[i]),
                  ),
              ],
            ),
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsValueTile(
                  title: l10n.customColorsTitle,
                  subtitle: l10n.customColorsSubtitle,
                  valueText: '',
                  showDivider: false,
                  onTap: onCustomize,
                ),
              ],
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appearanceSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appearanceSectionIntro,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ModeChip(
                label: l10n.themeModeSystem,
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
                label: l10n.themeModeLight,
                selected: isLight,
                onTap: () => viewModel.applyPreset(ThemePreset.light),
              ),
              _ModeChip(
                label: l10n.themeModeDark,
                selected: !isLight,
                onTap: () => viewModel.applyPreset(ThemePreset.darkModern),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FontFilePickerRow(
            label: l10n.uiFontLabel,
            description: l10n.uiFontDescription,
            fonts: viewModel.systemFonts,
            selectedPath: viewModel.ui.fontPath,
            isLoading: viewModel.isLoadingSystemFonts,
            onSelected: viewModel.selectUiFont,
            onImportPath: viewModel.importUiFontFromPath,
            onDeleteFont: viewModel.deleteImportedFont,
          ),
          ZephyrSettingsAdaptiveNumber(
            compact: false,
            title: l10n.uiFontSizeTitle,
            description: l10n.uiFontSizeDescription,
            value: viewModel.ui.fontSize,
            min: 11,
            max: 18,
            defaultValue: defaults.fontSize,
            suffix: 'px',
            divisions: 7,
            onChanged: viewModel.updateUiFontSize,
          ),
          ZephyrSettingsAdaptiveNumber(
            compact: false,
            title: l10n.cornerRadiusTitle,
            description: l10n.cornerRadiusDescription,
            value: viewModel.ui.cornerRadius,
            min: UiPreferences.minCornerRadius,
            max: UiPreferences.maxCornerRadius,
            defaultValue: defaults.cornerRadius,
            suffix: 'px',
            divisions: 20,
            onChanged: viewModel.updateCornerRadius,
          ),
          ZephyrSettingsAdaptiveNumber(
            compact: false,
            title: l10n.barCornerRadiusTitle,
            description: l10n.barCornerRadiusDescription,
            value: viewModel.ui.barCornerRadius,
            min: UiPreferences.minBarCornerRadius,
            max: UiPreferences.maxBarCornerRadius,
            defaultValue: defaults.barCornerRadius,
            suffix: 'px',
            divisions: 24,
            onChanged: viewModel.updateBarCornerRadius,
          ),
          ZephyrSettingsSwitchTile(
            title: l10n.showBordersTitle,
            subtitle: l10n.showBordersSubtitle,
            value: viewModel.ui.showBorders,
            onChanged: viewModel.updateShowBorders,
          ),
          ZephyrSettingsAdaptiveNumber(
            compact: false,
            title: l10n.sidebarItemInsetTitle,
            description: l10n.sidebarItemInsetDescription,
            value: viewModel.ui.sidebarItemInset,
            min: UiPreferences.minSidebarItemInset,
            max: UiPreferences.maxSidebarItemInset,
            defaultValue: defaults.sidebarItemInset,
            suffix: 'px',
            divisions: 24,
            onChanged: viewModel.updateSidebarItemInset,
          ),
          ZephyrSettingsAdaptiveNumber(
            compact: false,
            title: l10n.sidebarVolumeGapTitle,
            description: l10n.sidebarVolumeGapDescription,
            value: viewModel.ui.sidebarVolumeGap,
            min: UiPreferences.minSidebarVolumeGap,
            max: UiPreferences.maxSidebarVolumeGap,
            defaultValue: defaults.sidebarVolumeGap,
            suffix: 'px',
            divisions: 9,
            onChanged: viewModel.updateSidebarVolumeGap,
          ),
          const SizedBox(height: 10),
          Text(
            active == null
                ? l10n.themeCurrentCustomLong
                : l10n.themeCurrentPresetLong(_presetTitle(l10n, active)),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.themePresetsFooter,
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
                  l10n: l10n,
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
              label: Text(l10n.customizeTokensButton),
            ),
          ),
        ],
      );
    },
  );
}

class ThemeTokenEditor extends StatefulWidget {
  const ThemeTokenEditor({
    super.key,
    required this.viewModel,
    required this.onBack,
    this.showBackButton = true,
  });

  final ThemeViewModel viewModel;
  final VoidCallback onBack;
  final bool showBackButton;

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
    builder: (context, _) {
      final l10n = context.l10n;
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showBackButton) ...[
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.backToThemesButton),
          ),
          const SizedBox(height: 8),
        ],
        Text(l10n.themeTokensTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          l10n.themeTokensIntro,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView(
            children: [
              for (final token in ThemeToken.values)
                _TokenField(
                  label: _tokenLabel(l10n, token),
                  description: _tokenDescription(l10n, token),
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
            child: Text(l10n.restoreDarkModernDefaults),
          ),
        ),
      ],
    );
    },
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
    required this.l10n,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppLocalizations l10n;
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
                      _presetTitle(l10n, preset),
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

String _presetTitle(AppLocalizations l10n, ThemePreset preset) =>
    switch (preset) {
      ThemePreset.light => l10n.themePresetLight,
      ThemePreset.grey => l10n.themePresetGrey,
      ThemePreset.slate => l10n.themePresetSlate,
      ThemePreset.claude => l10n.themePresetClaude,
      ThemePreset.mint => l10n.themePresetMint,
      ThemePreset.purple => l10n.themePresetPurple,
      ThemePreset.hermes => l10n.themePresetHermes,
      ThemePreset.ocean => l10n.themePresetOcean,
      ThemePreset.darkModern => l10n.themePresetDarkModern,
    };

String _tokenLabel(AppLocalizations l10n, ThemeToken token) => switch (token) {
  ThemeToken.editorSurface => l10n.tokenEditorSurface,
  ThemeToken.sidebarSurface => l10n.tokenSidebarSurface,
  ThemeToken.controlSurface => l10n.tokenControlSurface,
  ThemeToken.border => l10n.tokenBorder,
  ThemeToken.divider => l10n.tokenDivider,
  ThemeToken.primaryText => l10n.tokenPrimaryText,
  ThemeToken.mutedText => l10n.tokenMutedText,
  ThemeToken.accent => l10n.tokenAccent,
  ThemeToken.cursor => l10n.tokenCursor,
};

String _tokenDescription(AppLocalizations l10n, ThemeToken token) =>
    switch (token) {
      ThemeToken.editorSurface => l10n.tokenEditorSurfaceDescription,
      ThemeToken.sidebarSurface => l10n.tokenSidebarSurfaceDescription,
      ThemeToken.controlSurface => l10n.tokenControlSurfaceDescription,
      ThemeToken.border => l10n.tokenBorderDescription,
      ThemeToken.divider => l10n.tokenDividerDescription,
      ThemeToken.primaryText => l10n.tokenPrimaryTextDescription,
      ThemeToken.mutedText => l10n.tokenMutedTextDescription,
      ThemeToken.accent => l10n.tokenAccentDescription,
      ThemeToken.cursor => l10n.tokenCursorDescription,
    };

String _hex(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _parseHex(String value) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  return match == null
      ? null
      : 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}
