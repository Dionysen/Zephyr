import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_theme_preferences_repository.dart';
import 'package:zephyr/data/services/theme_file_storage.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';

void main() {
  test(
    'round-trips every theme token through the app-support storage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-theme-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileThemePreferencesRepository(
        ThemeFileStorage(directoryProvider: () async => directory),
      );
      const expected = ThemeTokens(
        editorSurface: 0xFF010203,
        sidebarSurface: 0xFF040506,
        controlSurface: 0xFF070809,
        border: 0xFF101112,
        primaryText: 0xFFEEF0F2,
        mutedText: 0xFF818283,
        accent: 0xFFAABBCC,
      );

      await repository.save(expected);
      final actual = await repository.load();

      for (final token in ThemeToken.values) {
        expect(actual.valueOf(token), expected.valueOf(token));
      }
    },
  );
}
