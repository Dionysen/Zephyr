import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_settings.dart';

/// Shared font dropdown + "Choose file…" control for editor and UI fonts.
class FontFilePickerRow extends StatelessWidget {
  const FontFilePickerRow({
    super.key,
    required this.label,
    required this.description,
    required this.fonts,
    required this.selectedPath,
    required this.isLoading,
    required this.onSelected,
    required this.onImportPath,
  });

  final String label;
  final String description;
  final List<SystemFont> fonts;
  final String? selectedPath;
  final bool isLoading;
  final ValueChanged<SystemFont?> onSelected;
  final Future<bool> Function(String path) onImportPath;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ZephyrSettingsRow(
        label: label,
        description: description,
        child: const LinearProgressIndicator(),
      );
    }

    final selected = selectedPath ?? '';
    final items = <ZephyrDropdownItem<String>>[
      const ZephyrDropdownItem(value: '', label: 'Platform default'),
      for (final font in fonts)
        ZephyrDropdownItem(value: font.path, label: font.family),
    ];
    if (selected.isNotEmpty &&
        !items.any((item) => item.value == selected)) {
      final name = selected.split(RegExp(r'[/\\]')).last;
      items.add(ZephyrDropdownItem(value: selected, label: name));
    }

    return ZephyrSettingsRow(
      label: label,
      description: description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ZephyrDropdown<String>(
            value: selected,
            hint: 'Platform default',
            items: items,
            onChanged: (path) {
              if (path.isEmpty) {
                onSelected(null);
                return;
              }
              final font = fonts.where((item) => item.path == path).firstOrNull;
              if (font != null) {
                onSelected(font);
                return;
              }
              onSelected(SystemFont(family: path, path: path));
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _pickAndImport(context),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Choose font file…'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf', 'ttc', 'otc'],
    );
    final path = file?.path;
    if (path == null || path.isEmpty) {
      return;
    }
    final ok = await onImportPath(path);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Font imported into the app library.'
              : 'Could not import that font file.',
        ),
      ),
    );
  }
}
