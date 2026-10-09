import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_controls.dart';
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
      final viewModel = widget.viewModel;
      final preferences = viewModel.preferences;
      final compact = widget.compact;
      final defaults = EditorPreferences.defaults;

      final fontPicker = FontFilePickerRow(
        label: compact ? '字体' : 'Font',
        description: compact
            ? '写作区正文字体；导入后与 UI 字体共用应用字体库。'
            : 'Typeface used in the writing editor. Imports are shared with '
                  'the UI font library.',
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
          title: compact ? '字体大小' : 'Font size',
          description: compact
              ? '写作区正文字号。'
              : 'Size of the writing-column body text.',
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
          title: compact ? '标题字号' : 'Title size',
          description: compact
              ? '文章标题块字号。'
              : 'Font size of the chapter title above the body.',
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
            title: '标题居中',
            subtitle: '开则居中；关则与正文左边界对齐。',
            value: preferences.titleCentered,
            onChanged: viewModel.updateTitleCentered,
          )
        else
          ZephyrSettingsDesktopRow(
            label: 'Center title',
            description:
                'When on, center the title in the reading column; when off, '
                'align it to the body left edge.',
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
          title: compact ? '行高' : 'Line height',
          description: compact
              ? '段内行距倍数。'
              : 'Uniform line-height multiplier within a paragraph.',
          value: preferences.lineHeight,
          min: 1.2,
          max: 2.4,
          defaultValue: defaults.lineHeight,
          suffix: '×',
          onChanged: viewModel.updateLineHeight,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: compact ? '段间距' : 'Paragraph spacing',
          description: compact
              ? '段落之间的间距（字号倍数）。'
              : 'Gap between paragraphs, as a font-size multiplier.',
          value: preferences.paragraphSpacing,
          min: 0,
          max: 2.5,
          defaultValue: defaults.paragraphSpacing,
          suffix: '×',
          onChanged: viewModel.updateParagraphSpacing,
        ),
        ZephyrSettingsAdaptiveNumber(
          compact: compact,
          title: compact ? '首行缩进' : 'First-line indent',
          description: compact
              ? 'Tab 插入的缩进宽度；打开章节时也会应用。'
              : 'Width inserted by Tab, and applied when opening chapters. '
                    'Enter copies the previous paragraph\'s indent.',
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
          title: compact ? '栏宽' : 'Editor width',
          description: compact
              ? '阅读栏最大宽度；侧边距最小 12。'
              : 'Maximum width of the reading column.',
          value: preferences.maxContentWidth,
          // Compact screens are often < 480px; a lower floor lets the control
          // actually widen/narrow the column against the 12px gutter.
          min: compact ? 240 : 480,
          max: 1200,
          defaultValue: defaults.maxContentWidth,
          suffix: 'px',
          divisions: compact ? 96 : 72,
          showDivider: false,
          onChanged: viewModel.updateMaxContentWidth,
        ),
      ];

      if (compact) {
        // Non-scrollable fragment; the parent settings page owns scrolling.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ZephyrSettingsSection(
              footer: '更改会立即应用到写作区。',
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
            Text('Editor', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Typography and reading-column preferences apply immediately.',
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
