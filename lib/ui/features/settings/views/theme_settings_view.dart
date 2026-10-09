import 'package:flutter/material.dart';

import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_theme.dart';
import '../view_models/theme_view_model.dart';
import 'font_file_picker.dart';

class ThemeCatalog extends StatefulWidget {
  const ThemeCatalog({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final ThemeViewModel viewModel;
  final bool compact;

  @override
  State<ThemeCatalog> createState() => _ThemeCatalogState();
}

class _ThemeCatalogState extends State<ThemeCatalog> {
  var _customColorsExpanded = false;
  var _presetsExpanded = false;

  Future<void> _pickTokenColor(ThemeToken token) async {
    final current = Color(widget.viewModel.tokens.valueOf(token));
    final next = await showZephyrColorPicker(
      context,
      initialColor: current,
      title: _tokenLabel(context.l10n, token),
    );
    if (next == null || !mounted) return;
    widget.viewModel.update(token, next.toARGB32());
  }

  List<Widget> _customColorItems(AppLocalizations l10n, {required bool compact}) {
    final tokens = ThemeToken.values;
    return [
      for (var i = 0; i < tokens.length; i++)
        _ThemeColorTile(
          title: _tokenLabel(l10n, tokens[i]),
          subtitle: _tokenDescription(l10n, tokens[i]),
          color: Color(widget.viewModel.tokens.valueOf(tokens[i])),
          compact: compact,
          showDivider: true,
          onPick: () => _pickTokenColor(tokens[i]),
        ),
      if (compact)
        ZephyrSettingsListTile(
          title: l10n.restoreDefaultColors,
          showDivider: false,
          onTap: widget.viewModel.restoreDefaults,
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.viewModel.restoreDefaults,
            child: Text(l10n.restoreDefaultColors),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final viewModel = widget.viewModel;
      final active = viewModel.tokens.preset;
      final defaults = UiPreferences.defaults;
      final compact = widget.compact;
      final currentThemeLabel = active == null
          ? l10n.themeCurrentCustom
          : l10n.themeCurrentPreset(_presetTitle(l10n, active));
      final lightPreset = viewModel.lightTokens.preset;
      final darkPreset = viewModel.darkTokens.preset;

      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsChoiceTile<AppThemeMode>(
                  title: l10n.themeModeTitle,
                  subtitle: l10n.themeModeSubtitle,
                  selected: viewModel.themeMode,
                  choices: [
                    ZephyrSettingsChoice(
                      value: AppThemeMode.system,
                      label: l10n.themeModeSystem,
                    ),
                    ZephyrSettingsChoice(
                      value: AppThemeMode.light,
                      label: l10n.themeModeLight,
                    ),
                    ZephyrSettingsChoice(
                      value: AppThemeMode.dark,
                      label: l10n.themeModeDark,
                    ),
                  ],
                  valueLabel: _themeModeLabel(l10n, viewModel.themeMode),
                  onSelected: viewModel.setThemeMode,
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
              children: [
                ZephyrSettingsListTile(
                  title: l10n.themePresetsSectionTitle,
                  subtitle: currentThemeLabel,
                  showDivider: _presetsExpanded,
                  trailing: Icon(
                    _presetsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => setState(
                    () => _presetsExpanded = !_presetsExpanded,
                  ),
                ),
                if (_presetsExpanded)
                  for (var i = 0; i < ThemePreset.values.length; i++)
                    ZephyrSettingsListTile(
                      title: _presetTitle(l10n, ThemePreset.values[i]),
                      showDivider: i != ThemePreset.values.length - 1,
                      trailing: _presetTrailing(
                        context,
                        l10n,
                        preset: ThemePreset.values[i],
                        lightPreset: lightPreset,
                        darkPreset: darkPreset,
                        active: active,
                      ),
                      onTap: () =>
                          viewModel.applyPreset(ThemePreset.values[i]),
                    ),
              ],
            ),
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsListTile(
                  title: l10n.customColorsTitle,
                  subtitle: l10n.customColorsSubtitle,
                  showDivider: _customColorsExpanded,
                  trailing: Icon(
                    _customColorsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => setState(
                    () => _customColorsExpanded = !_customColorsExpanded,
                  ),
                ),
                if (_customColorsExpanded)
                  ..._customColorItems(l10n, compact: true),
              ],
            ),
          ],
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
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
                selected: viewModel.themeMode == AppThemeMode.system,
                onTap: () => viewModel.setThemeMode(AppThemeMode.system),
              ),
              _ModeChip(
                label: l10n.themeModeLight,
                selected: viewModel.themeMode == AppThemeMode.light,
                onTap: () => viewModel.setThemeMode(AppThemeMode.light),
              ),
              _ModeChip(
                label: l10n.themeModeDark,
                selected: viewModel.themeMode == AppThemeMode.dark,
                onTap: () => viewModel.setThemeMode(AppThemeMode.dark),
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
          ZephyrSettingsListTile(
            title: l10n.themePresetsSectionTitle,
            subtitle: active == null
                ? l10n.themeCurrentCustomLong
                : l10n.themeCurrentPresetLong(_presetTitle(l10n, active)),
            showDivider: _presetsExpanded,
            trailing: Icon(
              _presetsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () => setState(() => _presetsExpanded = !_presetsExpanded),
          ),
          if (_presetsExpanded)
            for (var i = 0; i < ThemePreset.values.length; i++)
              ZephyrSettingsListTile(
                title: _presetTitle(l10n, ThemePreset.values[i]),
                showDivider: i != ThemePreset.values.length - 1,
                trailing: _presetTrailing(
                  context,
                  l10n,
                  preset: ThemePreset.values[i],
                  lightPreset: lightPreset,
                  darkPreset: darkPreset,
                  active: active,
                ),
                onTap: () => viewModel.applyPreset(ThemePreset.values[i]),
              ),
          const SizedBox(height: 8),
          ZephyrSettingsListTile(
            title: l10n.customColorsTitle,
            subtitle: l10n.customColorsSubtitle,
            showDivider: _customColorsExpanded,
            trailing: Icon(
              _customColorsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () => setState(
              () => _customColorsExpanded = !_customColorsExpanded,
            ),
          ),
          if (_customColorsExpanded) ..._customColorItems(l10n, compact: false),
          const SizedBox(height: 24),
        ],
      );
    },
  );
}

String _themeModeLabel(AppLocalizations l10n, AppThemeMode mode) =>
    switch (mode) {
      AppThemeMode.system => l10n.themeModeSystem,
      AppThemeMode.light => l10n.themeModeLight,
      AppThemeMode.dark => l10n.themeModeDark,
    };

Widget? _presetTrailing(
  BuildContext context,
  AppLocalizations l10n, {
  required ThemePreset preset,
  required ThemePreset? lightPreset,
  required ThemePreset? darkPreset,
  required ThemePreset? active,
}) {
  final theme = Theme.of(context);
  final roles = <String>[
    if (preset == lightPreset) l10n.themeSlotLight,
    if (preset == darkPreset) l10n.themeSlotDark,
  ];
  if (roles.isEmpty && preset != active) return null;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < roles.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        _ThemeSlotBadge(label: roles[i]),
      ],
      if (preset == active) ...[
        if (roles.isNotEmpty) const SizedBox(width: 8),
        Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
      ],
    ],
  );
}

class _ThemeSlotBadge extends StatelessWidget {
  const _ThemeSlotBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1,
    );
    final fontSize = style?.fontSize ?? 11;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: style,
        strutStyle: StrutStyle(
          fontSize: fontSize,
          height: 1,
          forceStrutHeight: true,
          leading: 0,
        ),
      ),
    );
  }
}

/// Settings-row color token: same typography/spacing as other list tiles.
class _ThemeColorTile extends StatelessWidget {
  const _ThemeColorTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPick,
    required this.compact,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPick;
  final bool compact;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatch = _ColorSwatchButton(color: color, onTap: onPick);

    if (compact) {
      return ZephyrSettingsListTile(
        title: title,
        subtitle: subtitle,
        showDivider: showDivider,
        onTap: onPick,
        trailing: swatch,
      );
    }

    return ZephyrSettingsRow(
      label: title,
      description: subtitle,
      showDivider: showDivider,
      child: InkWell(
        onTap: onPick,
        borderRadius: context.zephyrBorderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              swatch,
              const SizedBox(width: 12),
              Text(
                _hex(color.toARGB32()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrBorderRadius;
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: const SizedBox(width: 28, height: 28),
      ),
    );
  }
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
