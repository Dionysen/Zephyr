import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../domain/models/theme_tokens.dart';
import '../../domain/models/ui_preferences.dart';
import 'zephyr_controls.dart';
import 'zephyr_status_bar.dart';

/// User-owned chrome corner radius exposed through [ThemeData.extensions].
@immutable
class ZephyrShapeTheme extends ThemeExtension<ZephyrShapeTheme> {
  const ZephyrShapeTheme({required this.cornerRadius});

  final double cornerRadius;

  BorderRadius get borderRadius => BorderRadius.circular(cornerRadius);

  OutlinedBorder get iconButtonShape =>
      ZephyrControls.iconButtonShapeFor(cornerRadius);

  OutlinedBorder get labeledButtonShape =>
      ZephyrControls.labeledButtonShapeFor(cornerRadius);

  OutlinedBorder get menuShape => ZephyrControls.menuShapeFor(cornerRadius);

  @override
  ZephyrShapeTheme copyWith({double? cornerRadius}) =>
      ZephyrShapeTheme(cornerRadius: cornerRadius ?? this.cornerRadius);

  @override
  ZephyrShapeTheme lerp(ThemeExtension<ZephyrShapeTheme>? other, double t) {
    if (other is! ZephyrShapeTheme) return this;
    return ZephyrShapeTheme(
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t)!,
    );
  }
}

extension ZephyrThemeContext on BuildContext {
  ZephyrShapeTheme get zephyrShape =>
      Theme.of(this).extension<ZephyrShapeTheme>() ??
      const ZephyrShapeTheme(
        cornerRadius: ZephyrControls.defaultCornerRadius,
      );

  double get zephyrCornerRadius => zephyrShape.cornerRadius;

  BorderRadius get zephyrBorderRadius => zephyrShape.borderRadius;
}

/// Builds the writing-shell theme from user-owned semantic tokens.
ThemeData zephyrTheme(
  ThemeTokens tokens, {
  UiPreferences ui = UiPreferences.defaults,
}) {
  final editor = Color(tokens.editorSurface);
  final sidebar = Color(tokens.sidebarSurface);
  final control = Color(tokens.controlSurface);
  final border = Color(tokens.border);
  final primaryText = Color(tokens.primaryText);
  final mutedText = Color(tokens.mutedText);
  final accent = Color(tokens.accent);
  final cursor = Color(tokens.cursor);
  final brightness = editor.computeLuminance() < .5
      ? Brightness.dark
      : Brightness.light;
  final selected = Color.alphaBlend(accent.withValues(alpha: .20), sidebar);
  final focus = Color.alphaBlend(accent.withValues(alpha: .5), border);
  final scale = ui.scale;
  final fontFamily = ui.fontFamily;
  final radius = ui.cornerRadius.clamp(
    UiPreferences.minCornerRadius,
    UiPreferences.maxCornerRadius,
  );
  final shape = ZephyrShapeTheme(cornerRadius: radius);
  final borderRadius = shape.borderRadius;

  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    extensions: [shape],
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: brightness)
        .copyWith(
          primary: accent,
          secondary: accent,
          secondaryContainer: selected,
          onSecondaryContainer: primaryText,
          surface: editor,
          onSurface: primaryText,
          surfaceContainerLowest: sidebar,
          surfaceContainerLow: Color.alphaBlend(
            Colors.white.withValues(alpha: .02),
            sidebar,
          ),
          surfaceContainer: Color.alphaBlend(
            Colors.white.withValues(alpha: .03),
            editor,
          ),
          surfaceContainerHigh: control,
          surfaceContainerHighest: Color.alphaBlend(
            Colors.white.withValues(alpha: .04),
            control,
          ),
          onSurfaceVariant: mutedText,
          outline: border,
          outlineVariant: Color.alphaBlend(
            Colors.black.withValues(alpha: .18),
            border,
          ),
          error: const Color(0xFFFFB4AB),
        ),
    scaffoldBackgroundColor: editor,
    dividerTheme: DividerThemeData(
      color: border,
      thickness: ZephyrControls.borderWidth,
      space: 1,
    ),
    iconTheme: IconThemeData(
      color: primaryText.withValues(alpha: .76),
      size: ZephyrControls.iconSize,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: primaryText.withValues(alpha: .76),
        iconSize: ZephyrControls.iconSize,
        padding: EdgeInsets.zero,
        minimumSize: const Size(
          ZephyrControls.buttonSize,
          ZephyrControls.buttonSize,
        ),
        fixedSize: const Size(
          ZephyrControls.buttonSize,
          ZephyrControls.buttonSize,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: shape.iconButtonShape,
        overlayColor: accent.withValues(alpha: .12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: primaryText,
        backgroundColor: accent.withValues(alpha: .24),
        iconSize: ZephyrControls.iconSize,
        shape: shape.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 20 * scale,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 15 * scale,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        color: primaryText,
        fontFamily: fontFamily,
        fontSize: 16 * scale,
        height: 1.75,
      ),
      bodySmall: TextStyle(
        color: mutedText,
        fontFamily: fontFamily,
        fontSize: 13 * scale,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        color: primaryText.withValues(alpha: .70),
        fontFamily: fontFamily,
        fontSize: 12 * scale,
      ),
      labelSmall: TextStyle(
        color: mutedText.withValues(alpha: .82),
        fontFamily: fontFamily,
        fontSize: 11 * scale,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: editor,
      foregroundColor: primaryText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: ZephyrStatusBar.styleFor(brightness),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: cursor,
      selectionColor: accent.withValues(alpha: .35),
      selectionHandleColor: cursor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: control,
      isDense: true,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: border,
          width: ZephyrControls.borderWidth,
        ),
        borderRadius: borderRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: focus,
          width: ZephyrControls.borderWidth,
        ),
        borderRadius: borderRadius,
      ),
      hintStyle: TextStyle(color: mutedText.withValues(alpha: .78)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: control,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: border, width: ZephyrControls.borderWidth),
      ),
    ),
    cardTheme: CardThemeData(
      color: control,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: border, width: ZephyrControls.borderWidth),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: control, borderRadius: borderRadius),
      textStyle: TextStyle(color: primaryText),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(control),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: .32),
        ),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: ZephyrControls.menuInsets),
        ),
        shape: WidgetStatePropertyAll(
          shape.menuShape.copyWith(
            side: BorderSide(
              color: border,
              width: ZephyrControls.borderWidth,
            ),
          ),
        ),
        visualDensity: VisualDensity.compact,
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: accent.withValues(alpha: .08),
  );
}
