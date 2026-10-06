import 'package:flutter/material.dart';

import 'zephyr_controls.dart';

/// One settings line: label on the left, control on the right.
class ZephyrSettingsRow extends StatelessWidget {
  const ZephyrSettingsRow({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: ZephyrControls.settingsLabelFlex,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: ZephyrControls.settingsControlFlex,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ZephyrControls.fieldHeight,
              ),
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class ZephyrSettingsSlider extends StatelessWidget {
  const ZephyrSettingsSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZephyrSettingsRow(
      label: label,
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: theme.sliderTheme.copyWith(
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                padding: EdgeInsets.zero,
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              '${value.toStringAsFixed(divisions == null ? 1 : 0)}$suffix',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
