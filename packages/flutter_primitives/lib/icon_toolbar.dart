import 'package:flutter/material.dart';

import 'chrome_controls.dart';

/// Shared mobile chrome for dense circular icon-tool rows (sidebar drawer
/// header, book sheet toolbar, …).
abstract final class IconToolbar {
  static ButtonStyle style(BuildContext context) => IconButton.styleFrom(
    iconSize: ChromeControls.mobileIconSize,
    padding: EdgeInsets.zero,
    minimumSize: const Size(
      ChromeControls.mobileButtonSize,
      ChromeControls.mobileButtonSize,
    ),
    fixedSize: const Size(
      ChromeControls.mobileButtonSize,
      ChromeControls.mobileButtonSize,
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    shape: const CircleBorder(),
  );

  /// Right-aligned row of [actions] (typically [IconButton]s using [style]).
  static Widget trailing({
    required List<Widget> actions,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(8, 0, 4, 4),
  }) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            actions[i],
          ],
        ],
      ),
    );
  }
}
