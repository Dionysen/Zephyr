import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_primitives/design/design_style.dart';

import '../zephyr_l10n.dart';

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

  /// Shared chrome color for settings top/bottom bars (sidebar surface).
  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLowest;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    if (DesignStyleScope.of(context) == DesignStyle.cupertino) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onBack,
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: backgroundColor(context),
      );
    }
    final theme = Theme.of(context);
    final background = backgroundColor(context);
    final foreground = theme.colorScheme.onSurface;

    return Material(
      color: background,
      elevation: 0,
      child: SizedBox(
        height: height,
        child: NavigationToolbar(
          leading: IconButton(
            onPressed: onBack,
            tooltip: context.l10n.settingsBackTooltip,
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
