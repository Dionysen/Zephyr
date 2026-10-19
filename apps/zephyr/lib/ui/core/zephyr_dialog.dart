import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_primitives/design/design_style.dart';

import 'window_chrome.dart';

/// Shared rules for modal prompts on desktop (phone-like width cap).
abstract final class ZephyrDialog {
  /// Typical phone logical width — desktop modals should not span the window.
  static const double maxContentWidth = 390;

  static const EdgeInsets desktopInsetPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  );

  static const BoxConstraints desktopConstraints = BoxConstraints(
    minWidth: 280,
    maxWidth: maxContentWidth,
  );
}

/// Prefer this over [showDialog] so desktop prompts stay a readable width.
Future<T?> showZephyrDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) {
  if (DesignStyleScope.of(context) == DesignStyle.cupertino) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      builder: (dialogContext) => zephyrConstrainDialogChild(
        _cupertinoDialogChild(builder(dialogContext)),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    builder: (context) => zephyrConstrainDialogChild(builder(context)),
  );
}

/// Convert common confirmation dialogs without changing their callbacks.
/// Complex or specially styled dialogs keep their Material implementation.
Widget _cupertinoDialogChild(Widget child) {
  if (child is! AlertDialog || child.icon != null || child.actions == null) {
    return child;
  }
  final actions = child.actions!;
  if (actions.any((action) => !_isPlainDialogAction(action))) return child;
  return CupertinoAlertDialog(
    title: child.title,
    content: child.content,
    actions: [
      for (final action in actions)
        CupertinoDialogAction(
          onPressed: switch (action) {
            TextButton button => button.onPressed,
            FilledButton button => button.onPressed,
            OutlinedButton button => button.onPressed,
            _ => null,
          },
          child: switch (action) {
            TextButton button => button.child!,
            FilledButton button => button.child!,
            OutlinedButton button => button.child!,
            _ => const SizedBox.shrink(),
          },
        ),
    ],
  );
}

bool _isPlainDialogAction(Widget action) => switch (action) {
  TextButton button =>
    button.style == null && button.onLongPress == null && button.child != null,
  FilledButton button =>
    button.style == null && button.onLongPress == null && button.child != null,
  OutlinedButton button =>
    button.style == null && button.onLongPress == null && button.child != null,
  _ => false,
};

/// Applies [ZephyrDialog.desktopConstraints] on desktop for common dialog types.
Widget zephyrConstrainDialogChild(Widget child) {
  if (child is CupertinoAlertDialog) return child;
  if (!WindowChrome.isDesktop) return child;
  if (child is AlertDialog) {
    return _constrainAlertDialog(child);
  }
  if (child is Dialog) {
    return _constrainDialog(child);
  }
  return Dialog(
    insetPadding: ZephyrDialog.desktopInsetPadding,
    constraints: ZephyrDialog.desktopConstraints,
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

BoxConstraints _mergedDialogConstraints(BoxConstraints? existing) {
  final base = ZephyrDialog.desktopConstraints;
  if (existing == null) return base;
  return BoxConstraints(
    minWidth: math.max(existing.minWidth, base.minWidth),
    maxWidth: math.min(
      existing.maxWidth < double.infinity ? existing.maxWidth : base.maxWidth,
      base.maxWidth,
    ),
    minHeight: existing.minHeight,
    maxHeight: existing.maxHeight,
  );
}

AlertDialog _constrainAlertDialog(AlertDialog dialog) {
  return AlertDialog(
    key: dialog.key,
    icon: dialog.icon,
    iconPadding: dialog.iconPadding,
    iconColor: dialog.iconColor,
    title: dialog.title,
    titlePadding: dialog.titlePadding,
    titleTextStyle: dialog.titleTextStyle,
    content: dialog.content,
    contentPadding: dialog.contentPadding,
    contentTextStyle: dialog.contentTextStyle,
    actions: dialog.actions,
    actionsPadding: dialog.actionsPadding,
    actionsAlignment: dialog.actionsAlignment,
    actionsOverflowAlignment: dialog.actionsOverflowAlignment,
    actionsOverflowButtonSpacing: dialog.actionsOverflowButtonSpacing,
    buttonPadding: dialog.buttonPadding,
    backgroundColor: dialog.backgroundColor,
    elevation: dialog.elevation,
    shadowColor: dialog.shadowColor,
    surfaceTintColor: dialog.surfaceTintColor,
    semanticLabel: dialog.semanticLabel,
    insetPadding: dialog.insetPadding ?? ZephyrDialog.desktopInsetPadding,
    clipBehavior: dialog.clipBehavior,
    shape: dialog.shape,
    alignment: dialog.alignment,
    scrollable: dialog.scrollable,
    constraints: _mergedDialogConstraints(dialog.constraints),
  );
}

Dialog _constrainDialog(Dialog dialog) {
  return Dialog(
    key: dialog.key,
    backgroundColor: dialog.backgroundColor,
    elevation: dialog.elevation,
    shadowColor: dialog.shadowColor,
    surfaceTintColor: dialog.surfaceTintColor,
    insetPadding: dialog.insetPadding ?? ZephyrDialog.desktopInsetPadding,
    clipBehavior: dialog.clipBehavior,
    shape: dialog.shape,
    alignment: dialog.alignment,
    constraints: _mergedDialogConstraints(dialog.constraints),
    child: dialog.child,
  );
}

/// Approximate chrome above/below [AlertDialog.content] (title + actions +
/// dialog padding). Used when estimating a keyboard-safe max height.
const double _dialogChromeReserve = 160;

/// Soft-keyboard inset in logical pixels.
///
/// [DialogRoute] clears [MediaQuery.viewInsets] inside the dialog, so read the
/// platform view directly when available.
double zephyrKeyboardBottom(BuildContext context) {
  final view = View.maybeOf(context);
  if (view != null) {
    return view.viewInsets.bottom / view.devicePixelRatio;
  }
  return MediaQuery.viewInsetsOf(context).bottom;
}

/// Wraps [AlertDialog.content] so tall forms stay within the space above the
/// soft keyboard: constrained max height + scroll.
Widget zephyrDialogScrollableContent({
  required BuildContext context,
  required Widget child,
  double? width,
  double maxFraction = 0.72,
}) {
  final media = MediaQuery.of(context);
  final keyboard = zephyrKeyboardBottom(context);
  final available =
      media.size.height -
      media.viewPadding.vertical -
      keyboard -
      _dialogChromeReserve;
  final cappedByFraction = media.size.height * maxFraction;
  final maxHeight = math.max(120.0, math.min(available, cappedByFraction));

  Widget body = SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    child: child,
  );
  body = ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: body,
  );
  if (width != null) {
    body = SizedBox(width: width, child: body);
  }
  return body;
}
