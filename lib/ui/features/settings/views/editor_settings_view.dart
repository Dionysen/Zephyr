import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';
import 'font_file_picker.dart';

class EditorSettingsView extends StatefulWidget {
  const EditorSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final EditorPreferencesViewModel viewModel;
  final bool compact;

  @override
  State<EditorSettingsView> createState() => _EditorSettingsViewState();
}

class _EditorSettingsViewState extends State<EditorSettingsView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final viewModel = widget.viewModel;
      final preferences = viewModel.preferences;
      final compact = widget.compact;
      final defaults = EditorPreferences.defaults;

      final fontPicker = FontFilePickerRow(
        label: l10n.editorFontLabel,
        description: l10n.editorFontDescription,
        fonts: viewModel.systemFonts,
        selectedPath: preferences.fontPath,
        isLoading: viewModel.isLoadingSystemFonts,
        onSelected: viewModel.selectFont,
        onImportPath: viewModel.importFontFromPath,
        onDeleteFont: viewModel.deleteImportedFont,
        compact: compact,
      );

      final numbers = <Widget>[
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorFontSizeTitle,
          description: l10n.editorFontSizeDescription,
          value: preferences.fontSize,
          min: 12,
          max: 32,
          defaultValue: defaults.fontSize,
          suffix: 'px',
          divisions: 20,
          onChanged: viewModel.updateFontSize,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorTitleSizeTitle,
          description: l10n.editorTitleSizeDescription,
          value: preferences.titleFontSize,
          min: EditorPreferences.minTitleFontSize,
          max: EditorPreferences.maxTitleFontSize,
          defaultValue: defaults.titleFontSize,
          suffix: 'px',
          divisions: (EditorPreferences.maxTitleFontSize -
                  EditorPreferences.minTitleFontSize)
              .round(),
          onChanged: viewModel.updateTitleFontSize,
        ),
        if (compact)
          ZephyrSettingsSwitchTile(
            title: l10n.editorTitleCenteredTitle,
            subtitle: l10n.editorTitleCenteredSubtitle,
            value: preferences.titleCentered,
            onChanged: viewModel.updateTitleCentered,
          )
        else
          ZephyrSettingsDesktopRow(
            label: l10n.editorTitleCenteredTitle,
            description: l10n.editorTitleCenteredSubtitle,
            child: Transform.scale(
              scale: ZephyrControls.settingsSwitchScale,
              alignment: Alignment.centerLeft,
              child: Switch(
                value: preferences.titleCentered,
                onChanged: viewModel.updateTitleCentered,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorLineHeightTitle,
          description: l10n.editorLineHeightDescription,
          value: preferences.lineHeight,
          min: 1.2,
          max: 2.4,
          defaultValue: defaults.lineHeight,
          suffix: '×',
          onChanged: viewModel.updateLineHeight,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorParagraphSpacingTitle,
          description: l10n.editorParagraphSpacingDescription,
          value: preferences.paragraphSpacing,
          min: 0,
          max: 2.5,
          defaultValue: defaults.paragraphSpacing,
          suffix: '×',
          onChanged: viewModel.updateParagraphSpacing,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorFirstLineIndentTitle,
          description: l10n.editorFirstLineIndentDescription,
          value: preferences.firstLineIndent.toDouble(),
          min: 0,
          max: 4,
          defaultValue: defaults.firstLineIndent.toDouble(),
          suffix: ' ch',
          divisions: 4,
          onChanged: (value) => viewModel.updateFirstLineIndent(value.round()),
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorMarginLeftTitle,
          description: l10n.editorMarginLeftDescription,
          value: preferences.marginLeft,
          min: EditorPreferences.minMargin,
          max: EditorPreferences.maxMargin,
          defaultValue: defaults.marginLeft,
          suffix: 'px',
          divisions: EditorPreferences.maxMargin.toInt(),
          onChanged: viewModel.updateMarginLeft,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: l10n.editorMarginRightTitle,
          description: l10n.editorMarginRightDescription,
          value: preferences.marginRight,
          min: EditorPreferences.minMargin,
          max: EditorPreferences.maxMargin,
          defaultValue: defaults.marginRight,
          suffix: 'px',
          divisions: EditorPreferences.maxMargin.toInt(),
          showDivider: false,
          onChanged: viewModel.updateMarginRight,
        ),
      ];

      if (compact) {
        // Non-scrollable fragment; the parent settings page owns scrolling.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZephyrSettingsSection(
              footer: l10n.editorSectionFooter,
              children: [fontPicker, ...numbers],
            ),
          ],
        );
      }

      return Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          children: [
            Text(
              l10n.editorSectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editorSectionIntro,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            fontPicker,
            ...numbers,
          ],
        ),
      );
    },
  );
}
