import 'package:flutter/material.dart';

import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_settings.dart';
import '../../editor/view_models/editor_preferences_view_model.dart';

class EditorSettingsView extends StatefulWidget {
  const EditorSettingsView({super.key, required this.viewModel});

  final EditorPreferencesViewModel viewModel;

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
            _FontRow(viewModel: viewModel),
            ZephyrSettingsSlider(
              label: 'Font size',
              description: 'Size of the writing-column body text.',
              value: preferences.fontSize,
              min: 12,
              max: 32,
              suffix: 'px',
              onChanged: viewModel.updateFontSize,
            ),
            ZephyrSettingsSlider(
              label: 'Line height',
              description: 'Uniform line-height multiplier within a paragraph.',
              value: preferences.lineHeight,
              min: 1.2,
              max: 2.4,
              suffix: '×',
              onChanged: viewModel.updateLineHeight,
            ),
            ZephyrSettingsSlider(
              label: 'Paragraph spacing',
              description:
                  'Gap between paragraphs, as a font-size multiplier.',
              value: preferences.paragraphSpacing,
              min: 0,
              max: 2.5,
              suffix: '×',
              onChanged: viewModel.updateParagraphSpacing,
            ),
            ZephyrSettingsSlider(
              label: 'First-line indent',
              description:
                  'Indent applied to the first line of each paragraph.',
              value: preferences.firstLineIndent.toDouble(),
              min: 0,
              max: 4,
              suffix: ' ch',
              divisions: 4,
              onChanged: (value) =>
                  viewModel.updateFirstLineIndent(value.round()),
            ),
            ZephyrSettingsSlider(
              label: 'Editor width',
              description: 'Maximum width of the reading column.',
              value: preferences.maxContentWidth,
              min: 480,
              max: 1200,
              suffix: 'px',
              showDivider: false,
              onChanged: viewModel.updateMaxContentWidth,
            ),
          ],
        ),
      );
    },
  );
}

class _FontRow extends StatelessWidget {
  const _FontRow({required this.viewModel});

  final EditorPreferencesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingSystemFonts) {
      return const ZephyrSettingsRow(
        label: 'Font',
        description: 'Typeface used in the writing editor.',
        child: LinearProgressIndicator(),
      );
    }
    if (viewModel.systemFonts.isEmpty) {
      return ZephyrSettingsRow(
        label: 'Font',
        description: 'Typeface used in the writing editor.',
        child: Text(
          'Platform default',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    final fonts = viewModel.systemFonts;
    final selectedPath = viewModel.preferences.fontPath ?? '';
    return ZephyrSettingsRow(
      label: 'Font',
      description: 'Typeface used in the writing editor.',
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
            viewModel.selectFont(null);
            return;
          }
          final font = fonts.where((item) => item.path == path).firstOrNull;
          if (font != null) {
            viewModel.selectFont(font);
          }
        },
      ),
    );
  }
}
