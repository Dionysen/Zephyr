import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/app_theme_mode.dart';
import 'package:zephyr/domain/models/theme_color_pack.dart';
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
        lightPackId: ThemeColorPack.builtInId(ThemePreset.light),
        darkPackId: ThemeColorPack.builtInId(ThemePreset.darkModern),
        customPacks: const [],
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

  test('restoring defaults restores the selected theme colors', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.mint);
    model.update(ThemeToken.accent, 0xFF112233);
    model.updateUiFontSize(16);
    expect(model.tokens.accent, 0xFF112233);

    model.restoreDefaults();
    expect(model.tokens, ThemeTokens.presets[ThemePreset.mint]);
    expect(model.ui.fontSize, 16);
  });

  test('saving current colors creates a selectable custom pack', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.purple);
    model.update(ThemeToken.accent, 0xFFAABBCC);
    model.saveCurrentAsTheme('主题1');

    expect(model.customPacks, hasLength(1));
    expect(model.customPacks.single.name, '主题1');
    expect(model.lightPackId, model.customPacks.single.id);
    expect(model.tokens.accent, 0xFFAABBCC);

    model.update(ThemeToken.accent, 0xFF000001);
    model.restoreDefaults();
    expect(model.tokens.accent, 0xFFAABBCC);
    expect(model.nextDefaultThemeNumber(), 2);
  });

  test('custom packs can be renamed, copied, and deleted', () {
    final model = ThemeViewModel(_ThemeRepository());
    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.mint);
    model.saveCurrentAsTheme('主题1');
    final id = model.customPacks.single.id;

    model.renameCustomPack(id, '晨雾');
    expect(model.customPacks.single.name, '晨雾');

    model.copyCustomPack(id, '晨雾 副本');
    expect(model.customPacks, hasLength(2));
    expect(model.customPacks.last.name, '晨雾 副本');
    expect(model.customPacks.last.tokens, model.customPacks.first.tokens);
    expect(model.lightPackId, id);

    model.deleteCustomPack(id);
    expect(model.customPacks, hasLength(1));
    expect(model.customPacks.single.name, '晨雾 副本');
    expect(model.lightPackId, ThemeColorPack.builtInId(ThemePreset.light));
    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.light]);
  });

  test('applying a preset updates the active mode slot only', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.ocean);

    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.ocean]);
    expect(model.darkTokens, ThemeTokens.defaults);
    expect(model.tokens, ThemeTokens.presets[ThemePreset.ocean]);
    expect(model.lightPackId, ThemeColorPack.builtInId(ThemePreset.ocean));
  });

  test('light and dark modes can share the same preset', () {
    final model = ThemeViewModel(_ThemeRepository());

    model.setThemeMode(AppThemeMode.light);
    model.applyPreset(ThemePreset.mint);
    model.setThemeMode(AppThemeMode.dark);
    model.applyPreset(ThemePreset.mint);

    expect(model.lightTokens, ThemeTokens.presets[ThemePreset.mint]);
    expect(model.darkTokens, ThemeTokens.presets[ThemePreset.mint]);
    expect(model.lightPackId, model.darkPackId);
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
            lightPackId: ThemeColorPack.builtInId(ThemePreset.light),
            darkPackId: ThemeColorPack.builtInId(ThemePreset.darkModern),
            customPacks: const [],
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
