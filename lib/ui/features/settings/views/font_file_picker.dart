import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_settings.dart';

/// Font picker for editor / UI fonts.
///
/// Compact layouts use a disclosure row + bottom sheet; wide layouts keep the
/// dropdown and import button.
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
    this.compact = false,
    this.showDivider = true,
  });

  final String label;
  final String description;
  final List<SystemFont> fonts;
  final String? selectedPath;
  final bool isLoading;
  final ValueChanged<SystemFont?> onSelected;
  final Future<bool> Function(String path) onImportPath;
  final bool compact;
  final bool showDivider;

  String get _selectedLabel {
    final path = selectedPath ?? '';
    if (path.isEmpty) return 'Platform default';
    for (final font in fonts) {
      if (font.path == path) return font.family;
    }
    return path.split(RegExp(r'[/\\]')).last;
  }

  Future<void> _import(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['ttf', 'otf', 'ttc', 'otc'],
    );
    final path = file?.path;
    if (path == null || path.isEmpty) return;
    final ok = await onImportPath(path);
    if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (compact) {
        return ZephyrSettingsListTile(
          title: label,
          subtitle: description,
          showDivider: showDivider,
          trailing: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return ZephyrSettingsRow(
        label: label,
        description: description,
        showDivider: showDivider,
        child: const LinearProgressIndicator(),
      );
    }

    if (compact) {
      final choices = <ZephyrSettingsChoice<String>>[
        const ZephyrSettingsChoice(value: '', label: 'Platform default'),
        for (final font in fonts)
          ZephyrSettingsChoice(value: font.path, label: font.family),
      ];
      return ZephyrSettingsChoiceTile<String>(
        title: label,
        subtitle: description,
        choices: choices,
        selected: selectedPath ?? '',
        valueLabel: _selectedLabel,
        showDivider: showDivider,
        actionLabel: 'Choose font file…',
        onAction: () => _import(context),
        onSelected: (path) {
          if (path.isEmpty) {
            onSelected(null);
            return;
          }
          final font = fonts.where((item) => item.path == path).firstOrNull;
          onSelected(font ?? SystemFont(family: path, path: path));
        },
      );
    }

    final selected = selectedPath ?? '';
    final items = <ZephyrDropdownItem<String>>[
      const ZephyrDropdownItem(value: '', label: 'Platform default'),
      for (final font in fonts)
        ZephyrDropdownItem(value: font.path, label: font.family),
    ];
    if (selected.isNotEmpty && !items.any((item) => item.value == selected)) {
      items.add(
        ZephyrDropdownItem(value: selected, label: _selectedLabel),
      );
    }

    return ZephyrSettingsRow(
      label: label,
      description: description,
      showDivider: showDivider,
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
              onSelected(font ?? SystemFont(family: path, path: path));
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _import(context),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Choose font file…'),
            ),
          ),
        ],
      ),
    );
  }
}
