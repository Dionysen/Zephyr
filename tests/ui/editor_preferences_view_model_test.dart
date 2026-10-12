import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/zephyr_bundled_fonts.dart';
import 'package:zephyr/domain/repositories/editor_preferences_repository.dart';
import 'package:zephyr/ui/features/editor/view_models/editor_preferences_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/font_library.dart';

void main() {
  late _MemoryEditorRepository repository;
  late _FontRepository fontRepository;
  late FontLibrary fonts;
  late EditorPreferencesViewModel model;

  setUp(() {
    repository = _MemoryEditorRepository();
    fontRepository = _FontRepository();
    fonts = FontLibrary(fontRepository);
    model = EditorPreferencesViewModel(repository, fonts);
    addTearDown(() {
      model.dispose();
      fonts.dispose();
    });
  });

  test('loading a missing saved font clears the stale selection', () async {
    repository.value = EditorPreferences.defaults.copyWith(
      fontFamily: 'Missing',
      fontPath: '/missing/zephyr-font.ttf',
    );

    await model.load();

    expect(model.preferences.fontFamily, ZephyrBundledFonts.wenkaiLite);
    expect(model.preferences.fontPath, isNull);
  });

  test('loading can skip saved font registration', () async {
    repository.value = EditorPreferences.defaults.copyWith(
      fontFamily: 'Stored',
      fontPath: '/missing/zephyr-font.ttf',
    );

    await model.load(loadSavedFont: false);

    expect(model.preferences.fontFamily, 'Stored');
    expect(model.preferences.fontPath, '/missing/zephyr-font.ttf');
    expect(fontRepository.loadCalls, 0);
  });

  test(
    'selecting and clearing a font updates the active editor style',
    () async {
      await model.selectFont(_FontRepository.font);
      expect(model.preferences.fontFamily, 'Imported');
      expect(model.preferences.fontPath, _FontRepository.font.path);

      await model.selectFont(null);
      expect(model.preferences.fontFamily, ZephyrBundledFonts.wenkaiLite);
      expect(model.preferences.fontPath, isNull);
    },
  );

  test('editor measurements clamp to supported ranges', () {
    model.updateMarginLeft(-1);
    model.updateMarginRight(999);
    model.updateEditorWidth(1);
    model.updateTitleFontSize(999);

    expect(model.preferences.marginLeft, EditorPreferences.minMargin);
    expect(model.preferences.marginRight, EditorPreferences.maxMargin);
    expect(model.preferences.editorWidth, EditorPreferences.minEditorWidth);
    expect(model.preferences.titleFontSize, EditorPreferences.maxTitleFontSize);
  });

  testWidgets('rapid preference changes persist only the latest value', (
    tester,
  ) async {
    model.updateFontSize(17);
    await tester.pump(const Duration(milliseconds: 100));
    model.updateFontSize(19);
    await tester.pump(const Duration(milliseconds: 251));

    expect(repository.saves, 1);
    expect(repository.value.fontSize, 19);
  });
}

class _MemoryEditorRepository implements EditorPreferencesRepository {
  EditorPreferences value = EditorPreferences.defaults;
  int saves = 0;

  @override
  Future<EditorPreferences> load() async => value;

  @override
  Future<void> save(EditorPreferences preferences) async {
    saves++;
    value = preferences;
  }
}

class _FontRepository implements SystemFontRepository {
  static const font = SystemFont(
    family: 'Imported',
    path: '/imported.ttf',
    imported: true,
  );
  int loadCalls = 0;

  @override
  Future<List<SystemFont>> listFonts() async => [font];

  @override
  Future<String?> loadFont(SystemFont font) async {
    loadCalls++;
    return font.family;
  }

  @override
  Future<SystemFont?> importFont(String sourcePath) async => font;

  @override
  Future<bool> deleteImportedFont(SystemFont font) async => true;
}
