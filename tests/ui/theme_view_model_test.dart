import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/app_theme_mode.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';
import 'package:zephyr/domain/repositories/theme_preferences_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/theme_view_model.dart';

void main() {
  test('loads saved tokens and applies a changed token immediately', () async {
    final repository = _ThemeRepository(
      ThemeAppearance(
        mode: AppThemeMode.light,
        lightTokens: const ThemeTokens(
          editorSurface: 0xFF101010,
          sidebarSurface: 0xFF111111,
          controlSurface: 0xFF121212,
          border: 0xFF131313,
          divider: 0xFF101010,
          primaryText: 0xFFEEEEEE,
          mutedText: 0xFF888888,
          accent: 0xFF00AA00,
          cursor: 0xFFFFFFFF,
        ),
        darkTokens: ThemeTokens.defaults,
        ui: UiPreferences.defaults,
      ),
    );
    final model = ThemeViewModel(repository);

    await model.load();
    model.update(ThemeToken.accent, 0xFFCC8844);

    expect(model.tokens.editorSurface, 0xFF101010);
    expect(model.tokens.accent, 0xFFCC8844);
    expect(model.lightTokens.accent, 0xFFCC8844);
  });

  test('restoring defaults resets active colors only', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.update(ThemeToken.editorSurface, 0xFF000000);
    model.updateUiFontSize(16);
    model.setThemeMode(AppThemeMode.dark);
    model.applyPreset(ThemePreset.ocean);
    model.setThemeMode(AppThemeMode.light);
    model.restoreDefaults();

    expect(
      model.lightTokens.editorSurface,
      ThemeTokens.presets[ThemePreset.light]!.editorSurface,
    );
    expect(model.darkTokens, ThemeTokens.presets[ThemePreset.ocean]);
    expect(model.ui.fontSize, 16);

    model.setThemeMode(AppThemeMode.dark);
    model.update(ThemeToken.accent, 0xFF112233);
    model.restoreDefaults();
    expect(model.darkTokens, ThemeTokens.defaults);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
    expect(model.ui.fontSize, 16);
  });

  test('applying a preset updates the active mode slot only', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.ocean);

    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.ocean]);
    expect(model.darkTokens, ThemeTokens.defaults);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.ocean]);
  });

  test('light and dark modes can share the same preset', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.mint);
    model.setThemeMode(AppThemeMode.dark);
    model.applyPreset(ThemePreset.mint);

    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.mint]);
    expect(model.darkTokens, ThemeTokens.presets[ThemePreset.mint]);

    model.setThemeMode(AppThemeMode.light);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.mint]);
    model.setThemeMode(AppThemeMode.dark);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.mint]);
  });

  test('theme mode switches between independently assigned packs', () {
    final model = ThemeViewModel(_ThemeRepository());
    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.mint);
    model.setThemeMode(AppThemeMode.dark);
    model.applyPreset(ThemePreset.darkModern);

    model.setThemeMode(AppThemeMode.light);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.mint]);

    model.setThemeMode(AppThemeMode.dark);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.darkModern]);
  });

  test('ui font size updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.updateUiFontSize(12);

    expect(model.ui.fontSize, 12);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });

  test('corner radius updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.updateCornerRadius(12);

    expect(model.ui.cornerRadius, 12);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });

  test('bar corner radius updates independently of control radius', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.updateBarCornerRadius(16);

    expect(model.ui.barCornerRadius, 16);
    expect(model.ui.cornerRadius, UiPreferences.defaults.cornerRadius);
  });

  test('show borders updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository());

    expect(model.ui.showBorders, isTrue);
    model.updateShowBorders(false);

    expect(model.ui.showBorders, isFalse);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });

  test('sidebar item inset clamps to 0-24', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.updateSidebarItemInset(12);
    expect(model.ui.sidebarItemInset, 12);
    model.updateSidebarItemInset(40);
    expect(model.ui.sidebarItemInset, 24);
    model.updateSidebarItemInset(-2);
    expect(model.ui.sidebarItemInset, 0);
  });

  test('sidebar volume gap clamps to 1-10', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.updateSidebarVolumeGap(8);
    expect(model.ui.sidebarVolumeGap, 8);
    model.updateSidebarVolumeGap(40);
    expect(model.ui.sidebarVolumeGap, 10);
    model.updateSidebarVolumeGap(0);
    expect(model.ui.sidebarVolumeGap, 1);
  });

  test('immersive status bar updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository());

    expect(model.ui.immersiveStatusBar, isFalse);
    model.updateImmersiveStatusBar(true);
    expect(model.ui.immersiveStatusBar, isTrue);
    model.updateImmersiveStatusBar(false);
    expect(model.ui.immersiveStatusBar, isFalse);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });

  test('hide status bar icons updates independently of color tokens', () {
    final model = ThemeViewModel(_ThemeRepository());

    expect(model.ui.hideStatusBarIcons, isTrue);
    model.updateHideStatusBarIcons(false);
    expect(model.ui.hideStatusBarIcons, isFalse);
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });
}

class _ThemeRepository implements ThemePreferencesRepository {
  _ThemeRepository([ThemeAppearance? appearance])
    : appearance =
          appearance ??
          ThemeAppearance(
            mode: AppThemeMode.system,
            lightTokens: ThemeTokens.presets[ThemePreset.light]!,
            darkTokens: ThemeTokens.defaults,
            ui: UiPreferences.defaults,
          );

  ThemeAppearance appearance;

  @override
  Future<ThemeAppearance> load() async => appearance;

  @override
  Future<void> save(ThemeAppearance appearance) async {
    this.appearance = appearance;
  }
}
