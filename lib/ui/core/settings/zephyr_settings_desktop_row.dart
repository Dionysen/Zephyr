import 'package:flutter/material.dart';

import '../zephyr_controls.dart';

/// Desktop settings line: title/hint on the left, arbitrary control on the right.
class ZephyrSettingsDesktopRow extends StatelessWidget {
  const ZephyrSettingsDesktopRow({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.showDivider = true,
  });

  final String label;
  final String? description;
  final Widget child;
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: ZephyrControls.fieldHeight,
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: child),
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
