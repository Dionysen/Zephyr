import 'dart:math' as math;

import 'package:flutter/material.dart';

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
  final available = media.size.height -
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
