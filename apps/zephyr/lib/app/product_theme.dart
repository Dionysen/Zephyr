import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_primitives/design/design_style.dart';

import '../domain/models/theme_tokens.dart';
import '../domain/models/ui_preferences.dart';
import '../ui/core/zephyr_theme.dart';

/// Maps the product design choice to the compatibility Material theme.
///
/// Zephyr's existing screens still use Material ancestors. Material and
/// Cupertino modes change the global component defaults while migrated design
/// widgets can render native components through [DesignStyleScope].
ThemeData productTheme(
  DesignStyle style,
  ThemeTokens tokens, {
  UiPreferences ui = UiPreferences.defaults,
}) {
  final zephyr = zephyrTheme(tokens, ui: ui);
  if (style == DesignStyle.custom) return zephyr;

  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: zephyr.colorScheme,
    fontFamily: ui.fontFamily,
    textTheme: zephyr.textTheme,
    extensions: [zephyr.extension<ZephyrShapeTheme>()!],
    textSelectionTheme: zephyr.textSelectionTheme,
  );
  if (style == DesignStyle.material) return theme;

  const cupertinoRadius = BorderRadius.all(Radius.circular(12));
  const pageTransition = CupertinoPageTransitionsBuilder();
  return theme.copyWith(
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: pageTransition,
        TargetPlatform.iOS: pageTransition,
        TargetPlatform.macOS: pageTransition,
        TargetPlatform.windows: pageTransition,
        TargetPlatform.linux: pageTransition,
      },
    ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: theme.brightness,
      primaryColor: theme.colorScheme.primary,
      scaffoldBackgroundColor: theme.colorScheme.surface,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: cupertinoRadius),
    ),
    cardTheme: CardThemeData(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(borderRadius: cupertinoRadius),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: cupertinoRadius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: cupertinoRadius),
      ),
    ),
  );
}
