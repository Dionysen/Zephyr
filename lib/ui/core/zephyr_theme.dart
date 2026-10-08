import 'package:flutter/material.dart';

import '../../domain/models/theme_tokens.dart';
import 'zephyr_controls.dart';

/// Builds the writing-shell theme from user-owned semantic tokens.
ThemeData zephyrTheme(ThemeTokens tokens) {
  final editor = Color(tokens.editorSurface);
  final sidebar = Color(tokens.sidebarSurface);
  final control = Color(tokens.controlSurface);
  final border = Color(tokens.border);
  final primaryText = Color(tokens.primaryText);
  final mutedText = Color(tokens.mutedText);
  final accent = Color(tokens.accent);
  final brightness = editor.computeLuminance() < .5
      ? Brightness.dark
      : Brightness.light;
  final selected = Color.alphaBlend(accent.withValues(alpha: .20), sidebar);
  final focus = Color.alphaBlend(accent.withValues(alpha: .5), border);

  return ThemeData(
    useMaterial3: true,
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
        shape: ZephyrControls.iconButtonShape,
        overlayColor: accent.withValues(alpha: .12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: ZephyrControls.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryText,
        iconSize: ZephyrControls.iconSize,
        shape: ZephyrControls.labeledButtonShape,
        visualDensity: VisualDensity.compact,
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: primaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: primaryText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: TextStyle(color: primaryText, fontSize: 16, height: 1.75),
      bodySmall: TextStyle(color: mutedText, fontSize: 13, height: 1.3),
      labelMedium: TextStyle(
        color: primaryText.withValues(alpha: .70),
        fontSize: 12,
      ),
      labelSmall: TextStyle(
        color: mutedText.withValues(alpha: .82),
        fontSize: 11,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: editor,
      foregroundColor: primaryText,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: focus,
          width: ZephyrControls.borderWidth,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      hintStyle: TextStyle(color: mutedText.withValues(alpha: .78)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: control,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border, width: ZephyrControls.borderWidth),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: control),
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
          ZephyrControls.menuShape.copyWith(
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
