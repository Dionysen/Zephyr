import 'package:flutter/material.dart';

import 'zephyr_controls.dart';

/// Shared selectable-menu chrome: trailing checkmark; fill only on hover.
///
/// Used by [MenuAnchor] lists (chapter sort, overflow submenus) so selection
/// matches the same marker style across the app.
abstract final class ZephyrMenu {
  /// Hover / focus fill for menu rows (not applied to the selected state).
  static Color hoverFill(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: 0.10);

  /// [MenuItemButton] with optional leading icon and a trailing check when
  /// [selected]. Selected rows stay flat; only hovered/focused rows fill.
  static Widget selectableItem({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback? onPressed,
    Widget? leadingIcon,
    ButtonStyle? style,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = style ?? const ButtonStyle();
    return MenuItemButton(
      leadingIcon: leadingIcon,
      trailingIcon: selected
          ? Icon(
              Icons.check,
              size: ZephyrControls.iconSize,
              color: scheme.onSurface,
            )
          : null,
      style: base.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return hoverFill(scheme);
          }
          return Colors.transparent;
        }),
        minimumSize: const WidgetStatePropertyAll(
          Size(ZephyrControls.menuMinWidth, ZephyrControls.menuItemHeight),
        ),
        fixedSize: const WidgetStatePropertyAll(
          Size.fromHeight(ZephyrControls.menuItemHeight),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
