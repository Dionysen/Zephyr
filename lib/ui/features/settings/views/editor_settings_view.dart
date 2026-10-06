import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
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
      final selectedFont = viewModel.systemFonts
          .where((font) => font.path == preferences.fontPath)
          .firstOrNull;
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
