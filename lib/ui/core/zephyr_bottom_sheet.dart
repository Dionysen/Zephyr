import 'package:flutter/material.dart';

/// Shared density for modal bottom sheets (titles, rows, secondary text).
abstract final class ZephyrBottomSheet {
  static const double rowHeight = 38;
  static const double rowIconSize = 20;
  static const EdgeInsets titlePadding = EdgeInsets.fromLTRB(20, 4, 20, 8);
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );

  /// Sheet header — slightly smaller than [TextTheme.titleMedium], semibold.
  static TextStyle? titleStyle(ThemeData theme) =>
      theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  /// Primary label on a sheet row.
  static TextStyle? rowTitleStyle(ThemeData theme, {Color? color}) =>
      theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.25,
        color: color,
      );

  /// Secondary / subtitle under a row title.
  static TextStyle? rowSubtitleStyle(ThemeData theme, {Color? color}) {
    final muted =
        color ?? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72);
    return theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.25,
      color: muted,
    );
  }

  /// Hint / empty-state body under a sheet title.
  static TextStyle? bodyStyle(ThemeData theme) =>
      theme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.25,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
      );

  /// Dense [ListTile] chrome for sheet option lists.
  static ListTileThemeData listTileTheme(ThemeData theme) => ListTileThemeData(
    dense: true,
    visualDensity: VisualDensity.compact,
    minVerticalPadding: 0,
    minLeadingWidth: 28,
    contentPadding: listTilePadding,
    horizontalTitleGap: 12,
    iconColor: theme.colorScheme.onSurface.withValues(alpha: 0.76),
    titleTextStyle: rowTitleStyle(theme),
    subtitleTextStyle: rowSubtitleStyle(theme),
  );

  /// Wraps [child] so descendant [ListTile]s pick up [listTileTheme].
  static Widget listTheme({
    required BuildContext context,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return ListTileTheme(
      data: listTileTheme(theme),
      child: child,
    );
  }
}
