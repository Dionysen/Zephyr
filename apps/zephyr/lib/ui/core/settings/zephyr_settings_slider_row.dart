import 'package:flutter/material.dart';

import '../zephyr_controls.dart';

/// Desktop settings row with an inline [Slider] and numeric readout.
class ZephyrSettingsSliderRow extends StatelessWidget {
  const ZephyrSettingsSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.description,
    this.suffix = '',
    this.divisions,
    this.showDivider = true,
  });

  final String label;
  final String? description;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: ZephyrControls.settingsLabelFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(description!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: ZephyrControls.settingsControlFlex,
                child: Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: theme.sliderTheme.copyWith(
                          overlayShape: SliderComponentShape.noOverlay,
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
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
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}
