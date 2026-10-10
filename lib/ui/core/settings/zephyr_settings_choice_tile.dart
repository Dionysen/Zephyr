import 'package:flutter/material.dart';

import '../zephyr_bottom_sheet.dart';
import '../zephyr_l10n.dart';
import '../zephyr_theme.dart';
import 'zephyr_settings_value_tile.dart';

class ZephyrSettingsChoice<T> {
  const ZephyrSettingsChoice({
    required this.value,
    required this.label,
    this.subtitle,
    this.deletable = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final bool deletable;
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
  Future<bool> Function(T value)? onDelete,
  String? deleteConfirmTitle,
  String? deleteConfirmBody,
  String? deleteConfirmAction,
  String? deleteCancelAction,
}) {
  final l10n = context.l10n;
  final confirmTitle = deleteConfirmTitle ?? l10n.choiceDeleteTitle;
  final confirmBody = deleteConfirmBody ?? l10n.choiceDeleteBody;
  final confirmAction = deleteConfirmAction ?? l10n.actionDelete;
  final cancelAction = deleteCancelAction ?? l10n.actionCancel;
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
      return _ZephyrSettingsChoiceSheet<T>(
        title: title,
        initialChoices: choices,
        selected: selected,
        actionLabel: actionLabel,
        onAction: onAction,
        onDelete: onDelete,
        deleteConfirmTitle: confirmTitle,
        deleteConfirmBody: confirmBody,
        deleteConfirmAction: confirmAction,
        deleteCancelAction: cancelAction,
      );
    },
  );
}

class _ZephyrSettingsChoiceSheet<T> extends StatefulWidget {
  const _ZephyrSettingsChoiceSheet({
    required this.title,
    required this.initialChoices,
    required this.selected,
    this.actionLabel,
    this.onAction,
    this.onDelete,
    required this.deleteConfirmTitle,
    required this.deleteConfirmBody,
    required this.deleteConfirmAction,
    required this.deleteCancelAction,
  });

  final String title;
  final List<ZephyrSettingsChoice<T>> initialChoices;
  final T? selected;
  final String? actionLabel;
  final Future<void> Function()? onAction;
  final Future<bool> Function(T value)? onDelete;
  final String deleteConfirmTitle;
  final String deleteConfirmBody;
  final String deleteConfirmAction;
  final String deleteCancelAction;

  @override
  State<_ZephyrSettingsChoiceSheet<T>> createState() =>
      _ZephyrSettingsChoiceSheetState<T>();
}

class _ZephyrSettingsChoiceSheetState<T>
    extends State<_ZephyrSettingsChoiceSheet<T>> {
  late List<ZephyrSettingsChoice<T>> _choices = List.of(widget.initialChoices);

  Future<void> _delete(ZephyrSettingsChoice<T> choice) async {
    final onDelete = widget.onDelete;
    if (onDelete == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.deleteConfirmTitle),
        content: Text(widget.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.deleteCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.deleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await onDelete(choice.value);
    if (!mounted || !ok) return;
    setState(() {
      _choices = _choices.where((item) => item.value != choice.value).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.55;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: ZephyrBottomSheet.listTheme(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: ZephyrBottomSheet.titlePadding,
                child: Text(
                  widget.title,
                  style: ZephyrBottomSheet.titleStyle(theme),
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await widget.onAction!();
                      },
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text(widget.actionLabel!),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _choices.length,
                  itemBuilder: (context, index) {
                    final choice = _choices[index];
                    final isSelected = choice.value == widget.selected;
                    final showDelete =
                        choice.deletable && widget.onDelete != null;
                    return ListTile(
                      title: Text(choice.label),
                      subtitle: choice.subtitle == null
                          ? null
                          : Text(choice.subtitle!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: theme.colorScheme.primary,
                            ),
                          if (showDelete)
                            IconButton(
                              tooltip: widget.deleteConfirmAction,
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _delete(choice),
                            ),
                        ],
                      ),
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(choice.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    this.onDelete,
    this.deleteConfirmTitle,
    this.deleteConfirmBody,
    this.deleteConfirmAction,
    this.deleteCancelAction,
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
  final Future<bool> Function(T value)? onDelete;
  final String? deleteConfirmTitle;
  final String? deleteConfirmBody;
  final String? deleteConfirmAction;
  final String? deleteCancelAction;
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
    final l10n = context.l10n;
    final confirmTitle = deleteConfirmTitle ?? l10n.choiceDeleteTitle;
    final confirmBody = deleteConfirmBody ?? l10n.choiceDeleteBody;
    final confirmAction = deleteConfirmAction ?? l10n.actionDelete;
    final cancelAction = deleteCancelAction ?? l10n.actionCancel;
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
                onDelete: onDelete,
                deleteConfirmTitle: confirmTitle,
                deleteConfirmBody: confirmBody,
                deleteConfirmAction: confirmAction,
                deleteCancelAction: cancelAction,
              );
              if (next == null) return;
              onSelected(next);
            },
    );
  }
}
