import 'package:flutter/material.dart';

import 'zephyr_settings_number_picker.dart';
import 'zephyr_settings_slider_row.dart';

/// Number setting that uses an inline slider on wide layouts and a tappable
/// value tile + dialog on compact (mobile) layouts.
class ZephyrSettingsAdaptiveNumber extends StatelessWidget {
  const ZephyrSettingsAdaptiveNumber({
    super.key,
    required this.compact,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.onChanged,
    this.description,
    this.suffix = '',
    this.divisions,
    this.showDivider = true,
    this.formatValue,
  });

  final bool compact;
  final String title;
  final String? description;
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String suffix;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final bool showDivider;
  final ZephyrNumberPickerFormatter? formatValue;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return ZephyrSettingsNumberTile(
        title: title,
        subtitle: description,
        value: value,
        min: min,
        max: max,
        defaultValue: defaultValue,
        suffix: suffix,
        divisions: divisions,
        showDivider: showDivider,
        formatValue: formatValue,
        onChanged: onChanged,
      );
    }
    return ZephyrSettingsSliderRow(
      label: title,
      description: description,
      value: value,
      min: min,
      max: max,
      suffix: suffix,
      divisions: divisions,
      showDivider: showDivider,
      onChanged: onChanged,
    );
  }
}
