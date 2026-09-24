import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../domain/models/theme_tokens.dart';

/// Desktop chrome for the settings isolate: hidden system title bar and close
/// that hides instead of tearing down the Flutter engine.
Future<void> bootstrapDesktopSettingsWindow() async {
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
    return;
  }
  try {
    await windowManager.ensureInitialized();
    final surface = Color(ThemeTokens.defaults.editorSurface);
    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: const Size(1120, 760),
        minimumSize: const Size(520, 400),
        center: true,
        title: 'Zephyr Settings',
        titleBarStyle: TitleBarStyle.hidden,
        windowButtonVisibility: false,
        backgroundColor: surface,
      ),
      () async {},
    );
    await windowManager.setBackgroundColor(surface);
    await windowManager.setPreventClose(true);
  } on Object catch (error, stackTrace) {
    developer.log(
      'Settings window chrome unavailable; using native frame.',
      name: 'zephyr.settings',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
