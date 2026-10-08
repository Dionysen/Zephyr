import 'package:flutter/material.dart';

import '../zephyr_theme.dart';
import 'zephyr_settings_value_tile.dart';

/// Result of [showZephyrSettingsNumberPicker].
typedef ZephyrNumberPickerFormatter = String Function(double value);

/// Opens a dialog to pick a numeric value in [[min], [max]].
///
/// The default value is labeled in the dialog (e.g. "默认 16").
Future<double?> showZephyrSettingsNumberPicker(
  BuildContext context, {
  required String title,
  required double value,
  required double min,
  required double max,
  required double defaultValue,
  String suffix = '',
  int? divisions,
  String? description,
  ZephyrNumberPickerFormatter? formatValue,
}) {
  return showDialog<double>(
    context: context,
    builder: (context) => _ZephyrSettingsNumberPickerDialog(
      title: title,
      value: value,
      min: min,
      max: max,
      defaultValue: defaultValue,
      suffix: suffix,
      divisions: divisions,
      description: description,
      formatValue: formatValue,
    ),
  );
}

class _ZephyrSettingsNumberPickerDialog extends StatefulWidget {
  const _ZephyrSettingsNumberPickerDialog({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.suffix,
    required this.divisions,
    required this.description,
    required this.formatValue,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String suffix;
  final int? divisions;
  final String? description;
  final ZephyrNumberPickerFormatter? formatValue;

  @override
  State<_ZephyrSettingsNumberPickerDialog> createState() =>
      _ZephyrSettingsNumberPickerDialogState();
}

class _ZephyrSettingsNumberPickerDialogState
    extends State<_ZephyrSettingsNumberPickerDialog> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value.clamp(widget.min, widget.max);
  }

  String _format(double value) {
    if (widget.formatValue != null) {
      return widget.formatValue!(value);
    }
    final decimals = widget.divisions == null ? 1 : 0;
    return '${value.toStringAsFixed(decimals)}${widget.suffix}';
  }

  double _step() {
    if (widget.divisions == null || widget.divisions! <= 0) {
      final span = widget.max - widget.min;
      return span <= 0 ? 1 : span / 20;
    }
    return (widget.max - widget.min) / widget.divisions!;
  }

  void _nudge(double delta) {
    final next = (_value + delta).clamp(widget.min, widget.max);
    final step = _step();
    final snapped = widget.divisions == null
        ? next
        : (widget.min +
                  (((next - widget.min) / step).round() * step))
              .clamp(widget.min, widget.max);
    setState(() => _value = snapped.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrCornerRadius;
    final defaultLabel = _format(widget.defaultValue);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.description != null) ...[
            Text(widget.description!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
          Text(
            _format(_value),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '默认 $defaultLabel',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _value <= widget.min
                    ? null
                    : () => _nudge(-_step()),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Slider(
                  value: _value,
                  min: widget.min,
                  max: widget.max,
                  divisions: widget.divisions,
                  onChanged: (v) => setState(() => _value = v),
                ),
              ),
              IconButton(
                onPressed: _value >= widget.max
                    ? null
                    : () => _nudge(_step()),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => setState(() => _value = widget.defaultValue),
              child: Text('恢复默认（$defaultLabel）'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('完成'),
        ),
      ],
    );
  }
}

/// Mobile value tile that opens [showZephyrSettingsNumberPicker] on tap.
class ZephyrSettingsNumberTile extends StatelessWidget {
  const ZephyrSettingsNumberTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
    this.subtitle,
    this.suffix = '',
    this.divisions,
    this.showDivider = true,
    this.formatValue,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String suffix;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool showDivider;
  final ZephyrNumberPickerFormatter? formatValue;

  String _format(double v) {
    if (formatValue != null) return formatValue!(v);
    final decimals = divisions == null ? 1 : 0;
    return '${v.toStringAsFixed(decimals)}$suffix';
  }

  Future<void> _open(BuildContext context) async {
    final next = await showZephyrSettingsNumberPicker(
      context,
      title: title,
      value: value,
      min: min,
      max: max,
      defaultValue: defaultValue,
      suffix: suffix,
      divisions: divisions,
      description: subtitle,
      formatValue: formatValue,
    );
    if (next != null) {
      onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZephyrSettingsValueTile(
      title: title,
      subtitle: null,
      valueText: _format(value),
      showDivider: showDivider,
      onTap: () => _open(context),
    );
  }
}
