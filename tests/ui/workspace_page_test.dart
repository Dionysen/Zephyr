import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/models/settings_navigation.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';
import 'package:zephyr/domain/repositories/editor_preferences_repository.dart';
import 'package:zephyr/domain/repositories/settings_navigation_repository.dart';
import 'package:zephyr/domain/repositories/theme_preferences_repository.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
import 'package:zephyr/ui/core/zephyr_scope.dart';
import 'package:zephyr/ui/core/zephyr_theme.dart';
import 'package:zephyr/ui/features/editor/view_models/editor_preferences_view_model.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/settings_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/theme_view_model.dart';
import 'package:zephyr/ui/features/workspace/views/workspace_page.dart';

void main() {
  testWidgets('wide layout docks the shared sidebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand all'), findsOneWidget);
    expect(find.text('Volume A'), findsOneWidget);
  });

  testWidgets('compact layout uses a drawer instead of a second workspace', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open library'), findsOneWidget);
    expect(find.byTooltip('Hide sidebar'), findsNothing);
    expect(find.byTooltip('Collapse all'), findsNothing);

    await tester.tap(find.byTooltip('Open library'));
    await tester.pumpAndSettle();
    expect(find.text('Book A'), findsOneWidget);
    expect(find.byTooltip('Collapse all'), findsOneWidget);
  });

  testWidgets('settings open as an in-app route on every layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Theme'), findsWidgets);
  });

  testWidgets('settings restore the last opened group', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editor').first);
    await tester.pumpAndSettle();
    expect(find.text('Font size'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Font size'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
  });
}

Widget _app() {
  final library = LibraryViewModel(_LibraryRepository());
  final theme = ThemeViewModel(_ThemeRepository());
  final editorPreferences = EditorPreferencesViewModel(
    _PreferencesRepository(),
    _FontRepository(),
  );
  final settings = SettingsViewModel(_SettingsRepository());
  return ZephyrScope(
    library: library,
    theme: theme,
    editorPreferences: editorPreferences,
    settings: settings,
    child: MaterialApp(
      theme: zephyrTheme(theme.tokens),
      home: const WorkspacePage(),
    ),
  );
}

class _LibraryRepository implements WritingLibraryRepository {
  @override
  Future<WritingLibrary> loadLibrary() async => WritingLibrary(
    folders: const [WritingFolder(id: 'Default', name: 'Book A', rank: 0)],
    categories: const [
      WritingCategory(
        id: 'volume-a',
        folderId: 'Default',
        name: 'Volume A',
        rank: 0,
        collapsed: false,
      ),
    ],
    articles: [
      ArticleSummary(
        id: 'article',
        title: 'Chapter A',
        summary: '',
        folderId: 'Default',
        categoryId: 'volume-a',
        updatedAt: DateTime.utc(2026),
      ),
    ],
  );

  @override
  Future<WritingArticle> getArticle(String id) async => WritingArticle(
    id: 'article',
    title: 'Chapter A',
    content: 'Hello',
    summary: '',
    folderId: 'Default',
    categoryId: 'volume-a',
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<WritingArticle> createArticle({required String folderId}) async =>
      getArticle('article');

  @override
  Future<void> saveArticle(WritingArticle article) async {}

  @override
  LibraryLocation? get location => null;

  @override
  Future<LibraryLocation> openLibrary(String rootPath) =>
      throw UnimplementedError();

  @override
  Future<void> closeLibrary() async {}

  @override
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<void> trashArticle(String articleId) async {}

  @override
  Future<void> restoreArticle(
    String articleId, {
    required String folderId,
  }) async {}

  @override
  Future<List<ArticleHistory>> listHistory(String articleId) async => const [];

  @override
  Future<List<DailyWriting>> listDaily() async => const [];

  @override
  Future<Map<String, double>> readScrolls() async => const {};

  @override
  Future<void> writeScroll(String articleId, double offset) async {}
}

class _ThemeRepository implements ThemePreferencesRepository {
  @override
  Future<ThemeTokens> loadTokens() async => ThemeTokens.defaults;

  @override
  Future<UiPreferences> loadUi() async => UiPreferences.defaults;

  @override
  Future<void> save({
    required ThemeTokens tokens,
    required UiPreferences ui,
  }) async {}
}

class _PreferencesRepository implements EditorPreferencesRepository {
  @override
  Future<EditorPreferences> load() async => EditorPreferences.defaults;

  @override
  Future<void> save(EditorPreferences preferences) async {}
}

class _SettingsRepository implements SettingsNavigationRepository {
  SettingsNavigation navigation = SettingsNavigation.defaults;

  @override
  Future<SettingsNavigation> load() async => navigation;

  @override
  Future<void> save(SettingsNavigation navigation) async {
    this.navigation = navigation;
  }
}

class _FontRepository implements SystemFontRepository {
  @override
  Future<List<SystemFont>> listFonts() async => const [];

  @override
  Future<String?> loadFont(SystemFont font) async => null;
}
