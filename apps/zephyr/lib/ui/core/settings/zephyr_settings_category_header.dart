import 'package:flutter/material.dart';

/// Icon + title divider used between major settings categories on mobile.
class ZephyrSettingsCategoryHeader extends StatelessWidget {
  const ZephyrSettingsCategoryHeader({
    super.key,
    required this.icon,
    required this.title,
    this.padding = const EdgeInsets.fromLTRB(4, 8, 4, 10),
  });

  final IconData icon;
  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
