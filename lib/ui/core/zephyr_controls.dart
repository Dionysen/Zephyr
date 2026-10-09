import 'package:flutter/material.dart';

/// Shared chrome sizes and corner radii for toolbar controls.
///
/// Prefer [ZephyrShapeTheme] / `context.zephyrCornerRadius` for the live
/// user-owned radius. Helpers here build shapes for a given radius value.
abstract final class ZephyrControls {
  static const double buttonSize = 28;
  static const double iconSize = 16;

  /// Compact / mobile chrome: slightly larger circular icon buttons.
  static const double mobileButtonSize = 40;
  static const double mobileIconSize = 22;

  /// Fallback when a [BuildContext] theme extension is unavailable.
  static const double defaultCornerRadius = 8;

  static bool isCircularRadius(double radius) => radius >= buttonSize / 2;

  static OutlinedBorder iconButtonShapeFor(double radius) =>
      isCircularRadius(radius)
      ? const CircleBorder()
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static OutlinedBorder labeledButtonShapeFor(double radius) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isCircularRadius(radius) ? buttonSize / 2 : radius,
        ),
      );

  static OutlinedBorder menuShapeFor(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  static OutlinedBorder get iconButtonShape =>
      iconButtonShapeFor(defaultCornerRadius);

  static OutlinedBorder get labeledButtonShape =>
      labeledButtonShapeFor(defaultCornerRadius);

  static OutlinedBorder get menuShape => menuShapeFor(defaultCornerRadius);

  static const double fieldHeight = 36;
  static const double menuInsets = 4;

  /// Hairline width for themed outlines, cards, and dividers.
  static const double borderWidth = 1;

  /// Settings rows: label | control. Keep the window wide enough that the
  /// control column can still host a slider or dropdown.
  static const int settingsLabelFlex = 5;
  static const int settingsControlFlex = 3;
  static const Size minWindowSize = Size(920, 580);
}
