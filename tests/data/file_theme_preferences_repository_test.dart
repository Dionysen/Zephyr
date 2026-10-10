import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_theme_preferences_repository.dart';
import 'package:zephyr/data/services/theme_file_storage.dart';
import 'package:zephyr/domain/models/app_theme_mode.dart';
import 'package:zephyr/domain/models/editor_background.dart';
import 'package:zephyr/domain/models/theme_color_pack.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';
import 'package:zephyr/domain/repositories/theme_preferences_repository.dart';

void main() {
  test(
    'round-trips light/dark packs, custom themes, mode, and ui preferences',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-theme-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileThemePreferencesRepository(
        ThemeFileStorage(directoryProvider: () async => directory),
      );
      final custom = ThemeColorPack(
        id: 'custom_1',
        name: '主题1',
        tokens: const ThemeTokens(
          editorSurface: 0xFF112233,
          sidebarSurface: 0xFF223344,
          controlSurface: 0xFF334455,
          border: 0xFF445566,
          divider: 0xFF556677,
          primaryText: 0xFFEEF0F2,
          mutedText: 0xFF818283,
          accent: 0xFFAABBCC,
          cursor: 0xFFFFFFFF,
        ),
      );
      final expected = ThemeAppearance(
        mode: AppThemeMode.dark,
        lightTokens: const ThemeTokens(
          editorSurface: 0xFF010203,
          sidebarSurface: 0xFF040506,
          controlSurface: 0xFF070809,
          border: 0xFF101112,
          divider: 0xFF0A0B0C,
          primaryText: 0xFFEEF0F2,
          mutedText: 0xFF818283,
          accent: 0xFFAABBCC,
          cursor: 0xFFFFFFFF,
        ),
        darkTokens: custom.tokens,
        lightPackId: ThemeColorPack.builtInId(ThemePreset.grey),
        darkPackId: custom.id,
        customPacks: [custom],
        ui: const UiPreferences(
          fontFamily: 'Inter',
          fontPath: r'C:\Fonts\Inter.ttf',
          fontSize: 12,
          cornerRadius: 10,
          barCornerRadius: 14,
          showBorders: false,
          sidebarItemInset: 12,
          sidebarVolumeGap: 4,
          immersiveStatusBar: true,
          hideStatusBarIcons: false,
          hideQuickToolbar: true,
          localePreference: AppLocalePreference.system,
          lightEditorBackground: EditorBackgroundConfig(
            imagePath: r'C:\App\backgrounds\paper.jpg',
            fit: EditorBackgroundFit.cover,
            opacity: 0.3,
            blurSigma: 8,
          ),
          darkEditorBackground: EditorBackgroundConfig(
            imagePath: r'C:\App\backgrounds\night.webp',
            fit: EditorBackgroundFit.tile,
            opacity: 0.2,
            blurSigma: 0,
          ),
        ),
      );

      await repository.save(expected);
      final actual = await repository.load();

      expect(actual.mode, expected.mode);
      expect(actual.lightPackId, expected.lightPackId);
      expect(actual.darkPackId, expected.darkPackId);
      expect(actual.customPacks, expected.customPacks);
      for (final token in ThemeToken.values) {
        expect(
          actual.lightTokens.valueOf(token),
          expected.lightTokens.valueOf(token),
        );
        expect(
          actual.darkTokens.valueOf(token),
          expected.darkTokens.valueOf(token),
        );
      }
      expect(actual.ui.fontFamily, expected.ui.fontFamily);
      expect(actual.ui.fontPath, expected.ui.fontPath);
      expect(actual.ui.fontSize, expected.ui.fontSize);
      expect(actual.ui.cornerRadius, expected.ui.cornerRadius);
      expect(actual.ui.barCornerRadius, expected.ui.barCornerRadius);
      expect(actual.ui.showBorders, expected.ui.showBorders);
      expect(actual.ui.sidebarItemInset, expected.ui.sidebarItemInset);
      expect(actual.ui.sidebarVolumeGap, expected.ui.sidebarVolumeGap);
      expect(actual.ui.immersiveStatusBar, expected.ui.immersiveStatusBar);
      expect(actual.ui.hideStatusBarIcons, expected.ui.hideStatusBarIcons);
      expect(actual.ui.hideQuickToolbar, expected.ui.hideQuickToolbar);
      expect(actual.ui.localePreference, expected.ui.localePreference);
      expect(
        actual.ui.lightEditorBackground,
        expected.ui.lightEditorBackground,
      );
      expect(
        actual.ui.darkEditorBackground,
        expected.ui.darkEditorBackground,
      );
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

    final appearance = await repository.load();

    expect(appearance.ui.fontSize, UiPreferences.defaults.fontSize);
    expect(appearance.ui.cornerRadius, UiPreferences.defaults.cornerRadius);
    expect(appearance.ui.barCornerRadius, UiPreferences.defaults.barCornerRadius);
    expect(appearance.ui.showBorders, UiPreferences.defaults.showBorders);
    expect(
      appearance.ui.sidebarItemInset,
      UiPreferences.defaults.sidebarItemInset,
    );
    expect(
      appearance.ui.sidebarVolumeGap,
      UiPreferences.defaults.sidebarVolumeGap,
    );
    expect(
      appearance.ui.immersiveStatusBar,
      UiPreferences.defaults.immersiveStatusBar,
    );
    expect(
      appearance.ui.hideStatusBarIcons,
      UiPreferences.defaults.hideStatusBarIcons,
    );
    expect(
      appearance.ui.hideQuickToolbar,
      UiPreferences.defaults.hideQuickToolbar,
    );
    expect(appearance.ui.localePreference, UiPreferences.defaults.localePreference);
    expect(appearance.ui.fontFamily, isNull);
    expect(appearance.ui.fontPath, isNull);
    expect(appearance.darkTokens.cursor, ThemeTokens.defaults.cursor);
    expect(appearance.darkTokens.divider, ThemeTokens.defaults.divider);
    expect(appearance.mode, AppThemeMode.system);
    expect(appearance.customPacks, isEmpty);
  });

  test('legacy uiStatusBarMode immersive migrates to immersiveStatusBar', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-theme-status-legacy-',
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
      'uiStatusBarMode': 'immersive',
    });
    final appearance = await FileThemePreferencesRepository(storage).load();
    expect(appearance.ui.immersiveStatusBar, isTrue);
  });
}
