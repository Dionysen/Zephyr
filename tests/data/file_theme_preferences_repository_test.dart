import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_theme_preferences_repository.dart';
import 'package:zephyr/data/services/theme_file_storage.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';

void main() {
  test(
    'round-trips every theme token and ui preference through storage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-theme-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileThemePreferencesRepository(
        ThemeFileStorage(directoryProvider: () async => directory),
      );
      const expectedTokens = ThemeTokens(
        editorSurface: 0xFF010203,
        sidebarSurface: 0xFF040506,
        controlSurface: 0xFF070809,
        border: 0xFF101112,
        primaryText: 0xFFEEF0F2,
        mutedText: 0xFF818283,
        accent: 0xFFAABBCC,
        cursor: 0xFFFFFFFF,
      );
      const expectedUi = UiPreferences(
        fontFamily: 'Inter',
        fontPath: r'C:\Fonts\Inter.ttf',
        fontSize: 12,
        cornerRadius: 10,
      );

      await repository.save(tokens: expectedTokens, ui: expectedUi);
      final actualTokens = await repository.loadTokens();
      final actualUi = await repository.loadUi();

      for (final token in ThemeToken.values) {
        expect(actualTokens.valueOf(token), expectedTokens.valueOf(token));
      }
      expect(actualUi.fontFamily, expectedUi.fontFamily);
      expect(actualUi.fontPath, expectedUi.fontPath);
      expect(actualUi.fontSize, expectedUi.fontSize);
      expect(actualUi.cornerRadius, expectedUi.cornerRadius);
    },
  );

  test('missing ui keys fall back to defaults', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-theme-legacy-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = ThemeFileStorage(directoryProvider: () async => directory);
    await storage.write({
      'editorSurface': ThemeTokens.defaults.editorSurface,
      'sidebarSurface': ThemeTokens.defaults.sidebarSurface,
      'controlSurface': ThemeTokens.defaults.controlSurface,
      'border': ThemeTokens.defaults.border,
      'primaryText': ThemeTokens.defaults.primaryText,
      'mutedText': ThemeTokens.defaults.mutedText,
      'accent': ThemeTokens.defaults.accent,
    });
    final repository = FileThemePreferencesRepository(storage);

    final ui = await repository.loadUi();
    final tokens = await repository.loadTokens();

    expect(ui.fontSize, UiPreferences.defaults.fontSize);
    expect(ui.cornerRadius, UiPreferences.defaults.cornerRadius);
    expect(ui.fontFamily, isNull);
    expect(ui.fontPath, isNull);
    expect(tokens.cursor, ThemeTokens.defaults.cursor);
  });
}
