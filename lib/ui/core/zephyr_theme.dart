import 'package:flutter/material.dart';

/// Visual tokens for the quiet, content-first writing shell.
///
/// Colors are assigned by surface role rather than per-widget so a future
/// theme pack replaces one semantic palette instead of scattered literals.
final zephyrTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF9ACBA7),
    onPrimary: Color(0xFF102217),
    secondary: Color(0xFF9ACBA7),
    onSecondary: Color(0xFF102217),
    secondaryContainer: Color(0xFF25362B),
    onSecondaryContainer: Color(0xFFD7F6DE),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE8E8E8),
    surfaceContainerLowest: Color(0xFF171717),
    surfaceContainerLow: Color(0xFF1B1B1B),
    surfaceContainer: Color(0xFF202020),
    surfaceContainerHigh: Color(0xFF242424),
    surfaceContainerHighest: Color(0xFF2A2A2A),
    onSurfaceVariant: Color(0xFF999999),
    outline: Color(0xFF343434),
    outlineVariant: Color(0xFF2C2C2C),
    error: Color(0xFFFFB4AB),
  ),
  scaffoldBackgroundColor: const Color(0xFF1E1E1E),
  dividerTheme: const DividerThemeData(color: Color(0xFF303030), space: 1),
  iconTheme: const IconThemeData(color: Color(0xFFB9B9B9), size: 19),
  textTheme: const TextTheme(
    titleSmall: TextStyle(
      color: Color(0xFFE3E3E3),
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    bodyLarge: TextStyle(color: Color(0xFFE5E5E5), fontSize: 16, height: 1.75),
    bodySmall: TextStyle(color: Color(0xFF858585), fontSize: 13, height: 1.3),
    labelMedium: TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
    labelSmall: TextStyle(color: Color(0xFF747474), fontSize: 11),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Color(0xFFE8E8E8),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF242424),
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF303030)),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF697D6F)),
      borderRadius: BorderRadius.all(Radius.circular(6)),
    ),
    hintStyle: TextStyle(color: Color(0xFF686868)),
  ),
  tooltipTheme: const TooltipThemeData(
    decoration: BoxDecoration(color: Color(0xFF303030)),
    textStyle: TextStyle(color: Color(0xFFE8E8E8)),
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: const Color(0x143F7851),
);
