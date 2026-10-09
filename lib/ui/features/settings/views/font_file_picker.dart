import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';

/// Font picker for editor / UI fonts.
///
/// Compact layouts use a disclosure row + bottom sheet; wide layouts keep the
/// dropdown and import button. Imports are shared across UI and body pickers.
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
    this.onDeleteFont,
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
  final Future<bool> Function(SystemFont font)? onDeleteFont;
  final bool compact;
  final bool showDivider;

  SystemFont? get _selectedFont {
    final path = selectedPath;
    if (path == null || path.isEmpty) return null;
    return fonts.where((font) => font.path == path).firstOrNull;
  }

  String _selectedLabel(BuildContext context) {
    final l10n = context.l10n;
    final path = selectedPath ?? '';
    if (path.isEmpty) return l10n.platformDefaultFont;
    final font = _selectedFont;
    if (font != null) return font.family;
    return path.split(RegExp(r'[/\\]')).last;
  }

  Future<void> _import(BuildContext context) async {
    final l10n = context.l10n;
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
          ok ? l10n.fontImportSuccess : l10n.fontImportFailure,
        ),
      ),
    );
  }

  Future<bool> _delete(BuildContext context, SystemFont font) async {
    final l10n = context.l10n;
    final delete = onDeleteFont;
    if (delete == null || !font.imported) return false;

    if (!compact) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.fontDeleteDialogTitle),
          content: Text(l10n.fontDeleteDialogBody(font.family)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.actionDelete),
            ),
          ],
        ),
      );
      if (confirmed != true) return false;
    }

    final ok = await delete(font);
    if (!context.mounted) return ok;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.fontDeleteSuccess : l10n.fontDeleteFailure),
      ),
    );
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        ZephyrSettingsChoice(value: '', label: l10n.platformDefaultFont),
        for (final font in fonts)
          ZephyrSettingsChoice(
            value: font.path,
            label: font.family,
            deletable: font.imported && onDeleteFont != null,
          ),
      ];
      return ZephyrSettingsChoiceTile<String>(
        title: label,
        subtitle: description,
        choices: choices,
        selected: selectedPath ?? '',
        valueLabel: _selectedLabel(context),
        showDivider: showDivider,
        actionLabel: l10n.fontImportFromFile,
        onAction: () => _import(context),
        deleteConfirmTitle: l10n.fontDeleteDialogTitle,
        deleteConfirmBody: l10n.fontDeleteDialogBodyCompact,
        deleteConfirmAction: l10n.actionDelete,
        deleteCancelAction: l10n.actionCancel,
        onDelete: onDeleteFont == null
            ? null
            : (path) async {
                final font = fonts
                    .where((item) => item.path == path)
                    .firstOrNull;
                if (font == null) return false;
                return _delete(context, font);
              },
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
    final selectedFont = _selectedFont;
    final items = <ZephyrDropdownItem<String>>[
      ZephyrDropdownItem(value: '', label: l10n.platformDefaultFont),
      for (final font in fonts)
        ZephyrDropdownItem(value: font.path, label: font.family),
    ];
    if (selected.isNotEmpty && !items.any((item) => item.value == selected)) {
      items.add(
        ZephyrDropdownItem(value: selected, label: _selectedLabel(context)),
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
            hint: l10n.platformDefaultFont,
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
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(l10n.fontImportFromFile),
              ),
              if (selectedFont != null &&
                  selectedFont.imported &&
                  onDeleteFont != null)
                TextButton.icon(
                  onPressed: () => _delete(context, selectedFont),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.fontDeleteFromLibrary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
