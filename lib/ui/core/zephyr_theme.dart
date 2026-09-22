import 'package:flutter/material.dart';

final zephyrTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF88C99D),
    brightness: Brightness.dark,
    surface: const Color(0xFF111111),
  ),
  scaffoldBackgroundColor: const Color(0xFF111111),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xEE111111),
    foregroundColor: Color(0xFFF2F2F2),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF303030)),
  useMaterial3: true,
);
