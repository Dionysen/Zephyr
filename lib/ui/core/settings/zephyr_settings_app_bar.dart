import 'package:flutter/material.dart';

/// Compact settings top bar: deeper surface, back control on the leading edge.
class ZephyrSettingsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ZephyrSettingsAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.height = 52,
  });

  final String title;
  final VoidCallback onBack;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = Color.alphaBlend(
      theme.colorScheme.onSurface.withValues(alpha: 0.12),
      theme.colorScheme.surfaceContainerLowest,
    );
    final foreground = theme.colorScheme.onSurface;

    return Material(
      color: background,
      elevation: 0,
      child: SizedBox(
        height: height,
        child: NavigationToolbar(
          leading: IconButton(
            onPressed: onBack,
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back),
            color: foreground,
          ),
          middle: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerMiddle: true,
        ),
      ),
    );
  }
}
