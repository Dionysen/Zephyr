import 'package:flutter/material.dart';

import '../zephyr_theme.dart';
import 'zephyr_settings_value_tile.dart';

class ZephyrSettingsChoice<T> {
  const ZephyrSettingsChoice({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// Opens a modal list to pick one option.
///
/// Returns `null` when dismissed without a selection. Prefer non-nullable [T]
/// values (e.g. `''` for “platform default”) so dismiss is unambiguous.
Future<T?> showZephyrSettingsChoicePicker<T>(
  BuildContext context, {
  required String title,
  required List<ZephyrSettingsChoice<T>> choices,
  required T? selected,
  String? actionLabel,
  Future<void> Function()? onAction,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.zephyrCornerRadius + 4),
      ),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      final height = MediaQuery.sizeOf(context).height * 0.55;
      return SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              if (actionLabel != null && onAction != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onAction();
                      },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text(actionLabel),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    final isSelected = choice.value == selected;
                    return ListTile(
                      title: Text(choice.label),
                      subtitle: choice.subtitle == null
                          ? null
                          : Text(choice.subtitle!),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(choice.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Value tile that opens [showZephyrSettingsChoicePicker].
class ZephyrSettingsChoiceTile<T> extends StatelessWidget {
  const ZephyrSettingsChoiceTile({
    super.key,
    required this.title,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.subtitle,
    this.valueLabel,
    this.actionLabel,
    this.onAction,
    this.showDivider = true,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final List<ZephyrSettingsChoice<T>> choices;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String? valueLabel;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final bool showDivider;
  final bool enabled;

  String get _display {
    if (valueLabel != null) return valueLabel!;
    for (final choice in choices) {
      if (choice.value == selected) return choice.label;
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return ZephyrSettingsValueTile(
      title: title,
      subtitle: subtitle,
      valueText: _display,
      showDivider: showDivider,
      enabled: enabled,
      onTap: !enabled
          ? null
          : () async {
              final next = await showZephyrSettingsChoicePicker<T>(
                context,
                title: title,
                choices: choices,
                selected: selected,
                actionLabel: actionLabel,
                onAction: onAction,
              );
              if (next == null) return;
              onSelected(next);
            },
    );
  }
}
