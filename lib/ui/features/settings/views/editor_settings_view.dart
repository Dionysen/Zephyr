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
              _FontPickerField(
                fonts: viewModel.systemFonts,
                selected: selectedFont,
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

class _FontPickerField extends StatelessWidget {
  const _FontPickerField({
    required this.fonts,
    required this.selected,
    required this.onChanged,
  });

  final List<SystemFont> fonts;
  final SystemFont? selected;
  final ValueChanged<SystemFont?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'System font'),
      child: InkWell(
        onTap: () => _openPicker(context),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.family ?? 'Platform default',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<_FontPick>(
      context: context,
      builder: (context) => _FontPickerDialog(fonts: fonts, selected: selected),
    );
    if (result == null) {
      return;
    }
    onChanged(result.font);
  }
}

class _FontPick {
  const _FontPick(this.font);
  final SystemFont? font;
}

class _FontPickerDialog extends StatefulWidget {
  const _FontPickerDialog({required this.fonts, required this.selected});

  final List<SystemFont> fonts;
  final SystemFont? selected;

  @override
  State<_FontPickerDialog> createState() => _FontPickerDialogState();
}

class _FontPickerDialogState extends State<_FontPickerDialog> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _query.text.trim().toLowerCase();
    final matches = needle.isEmpty
        ? widget.fonts
        : widget.fonts
              .where((font) => font.family.toLowerCase().contains(needle))
              .toList();
    return AlertDialog(
      title: const Text('System font'),
      content: SizedBox(
        width: 420,
        height: 480,
        child: Column(
          children: [
            TextField(
              controller: _query,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search fonts',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      title: const Text('Platform default'),
                      selected: widget.selected == null,
                      onTap: () =>
                          Navigator.pop(context, const _FontPick(null)),
                    );
                  }
                  final font = matches[index - 1];
                  return ListTile(
                    title: Text(font.family),
                    selected: font.path == widget.selected?.path,
                    onTap: () => Navigator.pop(context, _FontPick(font)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
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
