import 'package:flutter/material.dart';

import '../../domain/models/theme_tokens.dart';

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
    dividerTheme: DividerThemeData(color: border, space: 1),
    iconTheme: IconThemeData(
      color: primaryText.withValues(alpha: .76),
      size: 19,
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
        borderSide: BorderSide(color: border),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: focus),
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      hintStyle: TextStyle(color: mutedText.withValues(alpha: .78)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: control,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: control),
      textStyle: TextStyle(color: primaryText),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: accent.withValues(alpha: .08),
  );
}
