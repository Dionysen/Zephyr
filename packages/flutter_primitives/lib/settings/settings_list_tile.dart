import 'package:flutter/material.dart';

/// Horizontal settings row: leading icon, title, optional trailing.
///
/// Mobile-style list item used as the base for switches, value disclosures,
/// and navigation rows.
class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.enabled = true,
  });

  static const double iconSize = 22;
  static const double _iconGap = 14;
  static const double _horizontalPadding = 16;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: enabled ? null : theme.disabledColor,
    );
    final subtitleStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.3,
      color: enabled
          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
          : theme.disabledColor,
    );

    return Column(
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(icon, size: iconSize, color: iconColor),
                  const SizedBox(width: _iconGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: _horizontalPadding,
            endIndent: _horizontalPadding,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
