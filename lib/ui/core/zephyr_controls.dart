import 'package:flutter/material.dart';

/// Shared chrome sizes and corner radii for toolbar controls.
///
/// Change [buttonRadius] to restyle every themed button. A value of
/// [buttonSize] / 2 or greater makes square icon buttons circular.
abstract final class ZephyrControls {
  static const double buttonSize = 28;
  static const double iconSize = 16;

  /// Rounded-rectangle corner radius. Set to [buttonSize] / 2 for a circle.
  static const double buttonRadius = 8;

  static bool get isCircular => buttonRadius >= buttonSize / 2;

  static OutlinedBorder get iconButtonShape => isCircular
      ? const CircleBorder()
      : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        );

  static OutlinedBorder get labeledButtonShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      isCircular ? buttonSize / 2 : buttonRadius,
    ),
  );

  static const double fieldHeight = 36;
  static const double menuInsets = 4;

  /// Settings rows: label | control. Keep the window wide enough that the
  /// control column can still host a slider or dropdown.
  static const int settingsLabelFlex = 5;
  static const int settingsControlFlex = 3;
  static const Size minWindowSize = Size(920, 580);

  static OutlinedBorder get menuShape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius));
}
