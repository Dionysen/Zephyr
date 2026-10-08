import 'package:flutter/material.dart';

import 'zephyr_settings_list_tile.dart';

/// Tappable row that shows the current value and a disclosure chevron.
class ZephyrSettingsValueTile extends StatelessWidget {
  const ZephyrSettingsValueTile({
    super.key,
    required this.title,
    required this.valueText,
    required this.onTap,
    this.subtitle,
    this.showDivider = true,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final String valueText;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ZephyrSettingsListTile(
      title: title,
      subtitle: subtitle,
      showDivider: showDivider,
      enabled: enabled,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
