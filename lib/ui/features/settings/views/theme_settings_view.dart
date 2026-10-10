import 'package:flutter/material.dart';

import '../../../../domain/models/app_theme_mode.dart';
import '../../../../domain/models/editor_background.dart';
import '../../../../domain/models/theme_color_pack.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../../domain/models/ui_preferences.dart';
import '../../../core/zephyr_dialog.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_theme.dart';
import '../view_models/theme_view_model.dart';
import 'editor_background_settings_page.dart';
import 'editor_background_settings_view.dart';
import 'font_file_picker.dart';

Future<void> _openBackgroundPage(
  BuildContext context, {
  required ThemeViewModel viewModel,
  required bool dark,
}) async {
  await viewModel.loadBackgroundImages();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    EditorBackgroundSettingsPage.route(dark: dark),
  );
}

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

  Future<void> _saveAsThemeColor() async {
    final viewModel = widget.viewModel;
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _ThemeNameDialog(
        title: l10n.saveThemeColorTitle,
        initialName: l10n.themePackNameDefault(viewModel.nextDefaultThemeNumber()),
      ),
    );
    if (name == null || !mounted) return;
    viewModel.saveCurrentAsTheme(name);
  }

  Future<void> _showCustomPackMenu(ThemeColorPack pack) async {
    if (pack.isBuiltIn) return;
    final l10n = context.l10n;
    final action = await showZephyrSettingsChoicePicker<_PackMenuAction>(
      context,
      title: pack.name,
      selected: null,
      choices: [
        ZephyrSettingsChoice(
          value: _PackMenuAction.rename,
          label: l10n.actionRename,
        ),
        ZephyrSettingsChoice(
          value: _PackMenuAction.copy,
          label: l10n.actionCopy,
        ),
        ZephyrSettingsChoice(
          value: _PackMenuAction.delete,
          label: l10n.actionDelete,
        ),
      ],
    );
    if (action == null || !mounted) return;
    final viewModel = widget.viewModel;
    switch (action) {
      case _PackMenuAction.rename:
        final name = await showDialog<String>(
          context: context,
          builder: (context) => _ThemeNameDialog(
            title: l10n.themePackRenameTitle,
            initialName: pack.name,
          ),
        );
        if (name == null || !mounted) return;
        viewModel.renameCustomPack(pack.id, name);
      case _PackMenuAction.copy:
        viewModel.copyCustomPack(pack.id, l10n.themePackCopyName(pack.name));
      case _PackMenuAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.themePackDeleteTitle),
            content: Text(l10n.themePackDeleteBody(pack.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.actionDelete),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        viewModel.deleteCustomPack(pack.id);
    }
  }

  List<Widget> _packTiles({
    required AppLocalizations l10n,
    required List<ThemeColorPack> packs,
    required String lightPackId,
    required String darkPackId,
    required String activePackId,
    required bool activeMatches,
  }) {
    final viewModel = widget.viewModel;
    return [
      for (var i = 0; i < packs.length; i++)
        ZephyrSettingsListTile(
          title: _packTitle(l10n, packs[i]),
          showDivider: i != packs.length - 1,
          trailing: _packTrailing(
            context,
            l10n,
            packId: packs[i].id,
            lightPackId: lightPackId,
            darkPackId: darkPackId,
            isActive: activeMatches && packs[i].id == activePackId,
          ),
          onTap: () => viewModel.applyPack(packs[i].id),
          onLongPress: packs[i].isBuiltIn
              ? null
              : () => _showCustomPackMenu(packs[i]),
        ),
    ];
  }

  Widget _expandedBlock(List<Widget> children) => _ExpandedSettingsBlock(
    children: children,
  );

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
      _CustomColorActions(
        compact: compact,
        onSave: _saveAsThemeColor,
        onRestore: widget.viewModel.restoreDefaults,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final viewModel = widget.viewModel;
      final packs = viewModel.colorPacks;
      final activePack = viewModel.activePack;
      final activeMatches =
          activePack != null && activePack.tokens == viewModel.tokens;
      final defaults = UiPreferences.defaults;
      final compact = widget.compact;
      final currentThemeLabel = activeMatches
          ? l10n.themeCurrentPreset(_packTitle(l10n, activePack))
          : l10n.themeCurrentCustom;
      final lightPackId = viewModel.lightPackId;
      final darkPackId = viewModel.darkPackId;
      final activePackId = viewModel.activePackId;

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
                ZephyrSettingsListTile(
                  title: l10n.themePresetsSectionTitle,
                  subtitle: currentThemeLabel,
                  showDivider: true,
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
                  _expandedBlock(
                    _packTiles(
                      l10n: l10n,
                      packs: packs,
                      lightPackId: lightPackId,
                      darkPackId: darkPackId,
                      activePackId: activePackId,
                      activeMatches: activeMatches,
                    ),
                  ),
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
                  _expandedBlock(_customColorItems(l10n, compact: true)),
              ],
            ),
            ZephyrSettingsSection(
              title: l10n.editorBackgroundSectionTitle,
              children: [
                _EditorBackgroundTile(
                  title: l10n.editorBackgroundLightTitle,
                  config: viewModel.ui.lightEditorBackground,
                  isCurrent: !viewModel.isEffectivelyDark,
                  showDivider: true,
                  onTap: () => _openBackgroundPage(
                    context,
                    viewModel: viewModel,
                    dark: false,
                  ),
                ),
                _EditorBackgroundTile(
                  title: l10n.editorBackgroundDarkTitle,
                  config: viewModel.ui.darkEditorBackground,
                  isCurrent: viewModel.isEffectivelyDark,
                  showDivider: false,
                  onTap: () => _openBackgroundPage(
                    context,
                    viewModel: viewModel,
                    dark: true,
                  ),
                ),
              ],
            ),
            ZephyrSettingsSection(
              children: [
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
          ZephyrSettingsListTile(
            title: l10n.themePresetsSectionTitle,
            subtitle: activeMatches
                ? l10n.themeCurrentPresetLong(_packTitle(l10n, activePack))
                : l10n.themeCurrentCustomLong,
            showDivider: true,
            trailing: Icon(
              _presetsExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () => setState(() => _presetsExpanded = !_presetsExpanded),
          ),
          if (_presetsExpanded)
            _expandedBlock(
              _packTiles(
                l10n: l10n,
                packs: packs,
                lightPackId: lightPackId,
                darkPackId: darkPackId,
                activePackId: activePackId,
                activeMatches: activeMatches,
              ),
            ),
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
          if (_customColorsExpanded)
            _expandedBlock(_customColorItems(l10n, compact: false)),
          const SizedBox(height: 16),
          Text(
            l10n.editorBackgroundSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _EditorBackgroundTile(
            title: l10n.editorBackgroundLightTitle,
            config: viewModel.ui.lightEditorBackground,
            isCurrent: !viewModel.isEffectivelyDark,
            showDivider: true,
            onTap: () => _openBackgroundPage(
              context,
              viewModel: viewModel,
              dark: false,
            ),
          ),
          _EditorBackgroundTile(
            title: l10n.editorBackgroundDarkTitle,
            config: viewModel.ui.darkEditorBackground,
            isCurrent: viewModel.isEffectivelyDark,
            showDivider: true,
            onTap: () => _openBackgroundPage(
              context,
              viewModel: viewModel,
              dark: true,
            ),
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

Widget? _packTrailing(
  BuildContext context,
  AppLocalizations l10n, {
  required String packId,
  required String lightPackId,
  required String darkPackId,
  required bool isActive,
}) {
  final theme = Theme.of(context);
  final roles = <String>[
    if (packId == lightPackId) l10n.themeSlotLight,
    if (packId == darkPackId) l10n.themeSlotDark,
  ];
  if (roles.isEmpty && !isActive) return null;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < roles.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        _ThemeSlotBadge(label: roles[i]),
      ],
      if (isActive) ...[
        if (roles.isNotEmpty) const SizedBox(width: 8),
        Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
      ],
    ],
  );
}

enum _PackMenuAction { rename, copy, delete }

class _ExpandedSettingsBlock extends StatelessWidget {
  const _ExpandedSettingsBlock({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class _CustomColorActions extends StatelessWidget {
  const _CustomColorActions({
    required this.compact,
    required this.onSave,
    required this.onRestore,
  });

  final bool compact;
  final VoidCallback onSave;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: context.zephyrBorderRadius,
    );
    ButtonStyle styleFor(Color background) => ButtonStyle(
      shape: WidgetStatePropertyAll(shape),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    Widget button({
      required VoidCallback onPressed,
      required Color background,
      required IconData icon,
      required String label,
    }) => FilledButton(
      onPressed: onPressed,
      style: styleFor(background),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: button(
            onPressed: onSave,
            background: scheme.secondaryContainer,
            icon: Icons.bookmark_add_outlined,
            label: l10n.saveAsThemeColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: button(
            onPressed: onRestore,
            background: scheme.surfaceContainerHighest,
            icon: Icons.restart_alt,
            label: l10n.restoreDefaultColors,
          ),
        ),
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SizedBox(height: 44, child: row),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SizedBox(height: 44, child: row),
    );
  }
}

class _ThemeNameDialog extends StatefulWidget {
  const _ThemeNameDialog({
    required this.title,
    required this.initialName,
  });

  final String title;
  final String initialName;

  @override
  State<_ThemeNameDialog> createState() => _ThemeNameDialogState();
}

class _ThemeNameDialogState extends State<_ThemeNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: zephyrDialogScrollableContent(
        context: context,
        width: 360,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.saveThemeColorNameLabel),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationNameRequired;
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
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

String _packTitle(AppLocalizations l10n, ThemeColorPack pack) {
  final preset = pack.builtInPreset;
  if (preset == null) return pack.name;
  return switch (preset) {
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
}

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

class _EditorBackgroundTile extends StatelessWidget {
  const _EditorBackgroundTile({
    required this.title,
    required this.config,
    required this.isCurrent,
    required this.showDivider,
    required this.onTap,
  });

  final String title;
  final EditorBackgroundConfig config;
  final bool isCurrent;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = editorBackgroundSummary(l10n, config);
    return ZephyrSettingsListTile(
      title: title,
      subtitle: isCurrent
          ? '${l10n.editorBackgroundCurrentBadge} · $subtitle'
          : subtitle,
      showDivider: showDivider,
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
