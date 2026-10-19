import 'package:flutter/material.dart';

import '../adaptive_breakpoints.dart';
import 'settings_desktop_row.dart';
import 'settings_section.dart';
import 'settings_slider_row.dart';
import 'settings_switch_tile.dart';
import 'settings_value_tile.dart';

/// A group of settings that renders as a card on compact layouts.
class SettingsGroup {
  const SettingsGroup({
    required this.items,
    this.title,
    this.icon,
    this.footer,
  });

  final String? title;
  final IconData? icon;
  final String? footer;
  final List<SettingsItem> items;
}

/// A setting rendered by [AdaptiveSettingsView] on both compact and wide UI.
abstract class SettingsItem {
  const SettingsItem({required this.title, required this.icon, this.subtitle});

  final String title;
  final IconData icon;
  final String? subtitle;

  Widget build(
    BuildContext context, {
    required bool compact,
    required bool last,
  });
}

/// A Boolean preference with a switch.
class SettingsToggleItem extends SettingsItem {
  const SettingsToggleItem({
    required super.title,
    required super.icon,
    required this.value,
    required this.onChanged,
    super.subtitle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(
    BuildContext context, {
    required bool compact,
    required bool last,
  }) {
    if (compact) {
      return SettingsSwitchTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        showDivider: !last,
      );
    }
    return SettingsDesktopRow(
      label: title,
      description: subtitle,
      showDivider: !last,
      child: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// A selectable value shown in [SettingsChoiceItem].
class SettingsChoice<T> {
  const SettingsChoice({required this.value, required this.label});

  final T value;
  final String label;
}

/// A preference selected from a list. The picker presentation adapts to width.
class SettingsChoiceItem<T> extends SettingsItem {
  const SettingsChoiceItem({
    required super.title,
    required super.icon,
    required this.value,
    required this.choices,
    required this.onChanged,
    super.subtitle,
  });

  final T value;
  final List<SettingsChoice<T>> choices;
  final ValueChanged<T>? onChanged;

  String get valueLabel {
    for (final choice in choices) {
      if (choice.value == value) return choice.label;
    }
    return value.toString();
  }

  Future<void> _pick(BuildContext context, bool compact) async {
    if (onChanged == null || choices.isEmpty) return;
    final options = ListView.builder(
      shrinkWrap: true,
      itemCount: choices.length,
      itemBuilder: (itemContext, index) {
        final choice = choices[index];
        return ListTile(
          title: Text(choice.label),
          selected: choice.value == value,
          trailing: choice.value == value ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(itemContext).pop(index),
        );
      },
    );
    final int? nextIndex;
    if (compact) {
      nextIndex = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                Flexible(child: options),
              ],
            ),
          ),
        ),
      );
    } else {
      nextIndex = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            height: (choices.length * 56.0).clamp(
              56.0,
              MediaQuery.sizeOf(dialogContext).height * 0.6,
            ),
            child: options,
          ),
        ),
      );
    }
    if (context.mounted && nextIndex != null) {
      final next = choices[nextIndex].value;
      if (next != value) onChanged?.call(next);
    }
  }

  @override
  Widget build(
    BuildContext context, {
    required bool compact,
    required bool last,
  }) {
    if (compact) {
      return SettingsValueTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: valueLabel,
        onTap: onChanged == null || choices.isEmpty
            ? null
            : () => _pick(context, true),
        enabled: onChanged != null && choices.isNotEmpty,
        showDivider: !last,
      );
    }
    return SettingsDesktopRow(
      label: title,
      description: subtitle,
      showDivider: !last,
      child: OutlinedButton(
        onPressed: onChanged == null || choices.isEmpty
            ? null
            : () => _pick(context, false),
        child: Text(valueLabel),
      ),
    );
  }
}

/// A numeric preference with an inline wide slider and a compact picker.
class SettingsNumberItem extends SettingsItem {
  const SettingsNumberItem({
    required super.title,
    required super.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.suffix = '',
    super.subtitle,
  }) : assert(max > min),
       assert(divisions == null || divisions > 0);

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String suffix;
  final ValueChanged<double>? onChanged;

  String _format(double number) =>
      '${number.toStringAsFixed(divisions == null ? 1 : 0)}$suffix';

  Future<void> _pick(BuildContext context) async {
    if (onChanged == null) return;
    var selected = value.clamp(min, max);
    final next = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_format(selected)),
                Slider(
                  value: selected,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (next) => setDialogState(() => selected = next),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: Text(
                MaterialLocalizations.of(dialogContext).okButtonLabel,
              ),
            ),
          ],
        ),
      ),
    );
    if (context.mounted && next != null && next != value) onChanged?.call(next);
  }

  @override
  Widget build(
    BuildContext context, {
    required bool compact,
    required bool last,
  }) {
    if (compact) {
      return SettingsValueTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: _format(value),
        onTap: onChanged == null ? null : () => _pick(context),
        enabled: onChanged != null,
        showDivider: !last,
      );
    }
    return SettingsSliderRow(
      label: title,
      description: subtitle,
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      suffix: suffix,
      onChanged: onChanged,
      showDivider: !last,
    );
  }
}

/// A preference that runs an action or opens another route.
class SettingsActionItem extends SettingsItem {
  const SettingsActionItem({
    required super.title,
    required super.icon,
    required this.onPressed,
    super.subtitle,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(
    BuildContext context, {
    required bool compact,
    required bool last,
  }) {
    if (compact) {
      return SettingsValueTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        valueText: '',
        onTap: onPressed,
        enabled: onPressed != null,
        showDivider: !last,
      );
    }
    return SettingsDesktopRow(
      label: title,
      description: subtitle,
      showDivider: !last,
      child: IconButton(
        onPressed: onPressed,
        tooltip: title,
        icon: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// An embeddable settings body that selects its layout from available width.
class AdaptiveSettingsView extends StatelessWidget {
  const AdaptiveSettingsView({
    super.key,
    required this.groups,
    this.breakpoint = AdaptiveBreakpoints.compact,
    this.maxContentWidth = 920,
    this.cornerRadius = 4,
  });

  final List<SettingsGroup> groups;
  final double breakpoint;
  final double maxContentWidth;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final compact = width < breakpoint;
      return ListView(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 32,
          vertical: 24,
        ),
        children: [
          Center(
            child: SizedBox(
              width: width > maxContentWidth ? maxContentWidth : width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in groups)
                    SettingsSection(
                      title: group.title,
                      icon: group.icon,
                      footer: group.footer,
                      cornerRadius: cornerRadius,
                      children: [
                        for (var index = 0; index < group.items.length; index++)
                          group.items[index].build(
                            context,
                            compact: compact,
                            last: index == group.items.length - 1,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Complete settings screen. Supply items once; width selects their layout.
class AdaptiveSettingsPage extends StatelessWidget {
  const AdaptiveSettingsPage({
    super.key,
    required this.title,
    required this.groups,
    this.onBack,
    this.breakpoint = AdaptiveBreakpoints.compact,
    this.maxContentWidth = 920,
    this.cornerRadius = 4,
  });

  final String title;
  final List<SettingsGroup> groups;
  final VoidCallback? onBack;
  final double breakpoint;
  final double maxContentWidth;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: onBack == null
          ? null
          : IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
    ),
    body: AdaptiveSettingsView(
      groups: groups,
      breakpoint: breakpoint,
      maxContentWidth: maxContentWidth,
      cornerRadius: cornerRadius,
    ),
  );
}
