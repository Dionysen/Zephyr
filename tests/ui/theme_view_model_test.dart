import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';
import 'package:zephyr/domain/repositories/theme_preferences_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/theme_view_model.dart';

void main() {
  test('loads saved tokens and applies a changed token immediately', () async {
    final repository = _ThemeRepository(
      const ThemeTokens(
        editorSurface: 0xFF101010,
        sidebarSurface: 0xFF111111,
        controlSurface: 0xFF121212,
        border: 0xFF131313,
        primaryText: 0xFFEEEEEE,
        mutedText: 0xFF888888,
        accent: 0xFF00AA00,
      ),
    );
    final model = ThemeViewModel(repository);

    await model.load();
    model.update(ThemeToken.accent, 0xFFCC8844);

    expect(model.tokens.editorSurface, 0xFF101010);
    expect(model.tokens.accent, 0xFFCC8844);
  });

  test('restoring defaults replaces every user token', () {
    final model = ThemeViewModel(_ThemeRepository(ThemeTokens.defaults));

    model.update(ThemeToken.editorSurface, 0xFF000000);
    model.updateUiFontSize(16);
    model.restoreDefaults();

    expect(model.tokens.editorSurface, ThemeTokens.defaults.editorSurface);
    expect(model.tokens.accent, ThemeTokens.defaults.accent);
    expect(model.ui.fontSize, UiPreferences.defaults.fontSize);
  });

  test('applying a preset replaces the complete semantic palette', () {
    final model = ThemeViewModel(_ThemeRepository(ThemeTokens.defaults));

    model.applyPreset(ThemePreset.purple);

    expect(model.tokens, ThemeTokens.presets[ThemePreset.purple]);
    expect(model.tokens.preset, ThemePreset.purple);
  });

  test('ui font size updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository(ThemeTokens.defaults));

    model.updateUiFontSize(12);

    expect(model.ui.fontSize, 12);
    expect(model.tokens, ThemeTokens.defaults);
  });
}

class _ThemeRepository implements ThemePreferencesRepository {
  _ThemeRepository(this.tokens, [this.ui = UiPreferences.defaults]);

  ThemeTokens tokens;
  UiPreferences ui;

  @override
  Future<ThemeTokens> loadTokens() async => tokens;

  @override
  Future<UiPreferences> loadUi() async => ui;

  @override
  Future<void> save({
    required ThemeTokens tokens,
    required UiPreferences ui,
  }) async {
    this.tokens = tokens;
    this.ui = ui;
  }
}
