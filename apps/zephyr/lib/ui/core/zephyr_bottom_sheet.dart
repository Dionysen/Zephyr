import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_primitives/design/design_style.dart';

import 'window_chrome.dart';
import 'zephyr_dialog.dart';

/// Shared density for modal bottom sheets (titles, rows, secondary text).
abstract final class ZephyrBottomSheet {
  static const double rowHeight = 38;
  static const double rowIconSize = 20;

  /// Header inset. Top is roomy enough for desktop dialogs (no drag handle);
  /// mobile sheets still look fine because the handle sits above the builder.
  static const EdgeInsets titlePadding = EdgeInsets.fromLTRB(20, 16, 20, 12);
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );

  /// Default desktop dialog width for sheet-style panels.
  static const double desktopDialogWidth = ZephyrDialog.maxContentWidth;

  /// Max height for short, fit-content sheets (choice pickers, brief lists).
  static double fitContentMaxHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.5;

  /// [DraggableScrollableSheet] sizes for half-open sheets that can expand.
  static const double sheetMinSize = 0.35;
  static const double sheetInitialSize = 0.5;
  static const double sheetMaxSize = 0.95;

  /// Sheet header — slightly smaller than [TextTheme.titleMedium], semibold.
  static TextStyle? titleStyle(ThemeData theme) => theme.textTheme.titleSmall
      ?.copyWith(fontWeight: FontWeight.w600, height: 1.2);

  /// Primary label on a sheet row.
  static TextStyle? rowTitleStyle(ThemeData theme, {Color? color}) => theme
      .textTheme
      .bodyMedium
      ?.copyWith(fontSize: 14, height: 1.25, color: color);

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
    return ListTileTheme(data: listTileTheme(theme), child: child);
  }

  /// Hairline between sheet rows (matches settings list density).
  static Widget rowDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      indent: listTilePadding.left,
      endIndent: listTilePadding.right,
      color: theme.dividerColor.withValues(alpha: 0.5),
    );
  }

  /// [child] plus an optional trailing divider.
  static Widget withRowDivider({
    required BuildContext context,
    required Widget child,
    bool showDivider = true,
  }) {
    if (!showDivider) return child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [child, rowDivider(context)],
    );
  }
}

/// Mobile: bottom sheet. Desktop: centered modal dialog.
///
/// Use this instead of [showModalBottomSheet] so sheet-style panels share one
/// presentation rule across the app.
Future<T?> showZephyrModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  ShapeBorder? shape,
  double desktopWidth = ZephyrBottomSheet.desktopDialogWidth,
  double desktopMaxHeightFraction = 0.72,

  /// When true, the desktop dialog shrink-wraps short menus instead of
  /// using a fixed panel height (still capped by [desktopMaxHeightFraction]).
  bool desktopFitContent = false,
  bool barrierDismissible = true,
}) {
  if (DesignStyleScope.of(context) == DesignStyle.cupertino) {
    if (WindowChrome.isDesktop) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (dialogContext) {
          final maxHeight =
              MediaQuery.sizeOf(dialogContext).height *
              desktopMaxHeightFraction;
          return Center(
            child: CupertinoPopupSurface(
              child: desktopFitContent
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: desktopWidth,
                        maxHeight: maxHeight,
                      ),
                      child: builder(dialogContext),
                    )
                  : SizedBox(
                      width: desktopWidth,
                      height: maxHeight,
                      child: builder(dialogContext),
                    ),
            ),
          );
        },
      );
    }
    return showCupertinoModalPopup<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (popupContext) => Align(
        alignment: Alignment.bottomCenter,
        child: CupertinoPopupSurface(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(popupContext).height * 0.9,
            ),
            child: builder(popupContext),
          ),
        ),
      ),
    );
  }
  if (WindowChrome.isDesktop) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        final maxHeight =
            MediaQuery.sizeOf(dialogContext).height * desktopMaxHeightFraction;
        final Widget child;
        if (desktopFitContent) {
          child = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktopWidth,
              maxHeight: maxHeight,
            ),
            child: builder(dialogContext),
          );
        } else {
          // Fixed size so DraggableScrollableSheet / Expanded layouts resolve.
          child = SizedBox(
            width: desktopWidth,
            height: maxHeight,
            child: builder(dialogContext),
          );
        }
        return Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: child,
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: shape,
    builder: builder,
  );
}
