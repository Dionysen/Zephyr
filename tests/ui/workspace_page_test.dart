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
import 'package:zephyr/ui/features/workspace/views/workspace_sidebar.dart';

void main() {
  testWidgets('volume header stays pinned only while its chapters scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(
      _LibraryRepository(scrollingSections: true),
    );
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();

    final scroll = find.descendant(
      of: find.byType(WorkspaceSidebar),
      matching: find.byType(CustomScrollView),
    );
    final initialHeaderTop = tester.getTopLeft(find.text('Volume A')).dy;
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        )
        .position;

    position.jumpTo(220);
    await tester.pumpAndSettle();
    expect(find.text('Volume A').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Volume A')).dy,
      closeTo(initialHeaderTop, 3),
    );

    position.jumpTo(position.maxScrollExtent * .75);
    await tester.pumpAndSettle();
    expect(find.text('Volume A').hitTestable(), findsNothing);
    expect(find.text('Volume B').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Volume B')).dy,
      closeTo(initialHeaderTop, 3),
    );
    await tester.tap(find.text('Volume B'));
    await tester.pumpAndSettle();
    expect(library.isVolumeExpanded('volume-b'), isFalse);
  });

  testWidgets(
    'collapsing the scrolled volume keeps the next volume at its start',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = LibraryViewModel(
        _LibraryRepository(scrollingSections: true),
      );
      await tester.pumpWidget(_app(library: library));
      await tester.pumpAndSettle();

      final scroll = find.descendant(
        of: find.byType(WorkspaceSidebar),
        matching: find.byType(CustomScrollView),
      );
      final initialHeaderTop = tester.getTopLeft(find.text('Volume A')).dy;
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;

      position.jumpTo(220);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Volume A')).dy,
        closeTo(initialHeaderTop, 3),
      );

      await tester.tap(find.text('Volume A'));
      await tester.pumpAndSettle();
      expect(library.isVolumeExpanded('volume-a'), isFalse);
      expect(find.text('Volume A').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Volume A')).dy,
        closeTo(initialHeaderTop, 3),
      );
      expect(find.text('Volume B').hitTestable(), findsOneWidget);
      expect(find.text('B chapter 0').hitTestable(), findsOneWidget);
      expect(find.text('B chapter 10').hitTestable(), findsNothing);
    },
  );

  testWidgets('trash appears in the book picker and shows discarded chapters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(_LibraryRepository());
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();
    expect(library.selectedBook?.id, 'Default');

    await tester.tap(find.text('Book A'));
    await tester.pumpAndSettle();
    final trashLabel = tester.widget<Text>(find.text('Trash'));
    final trashContext = tester.element(find.text('Trash'));
    final trashColor = Theme.of(trashContext).colorScheme.error;
    expect(trashLabel.style?.color, trashColor);
    expect(find.byIcon(Icons.book_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(library.selectedBook?.id, WritingFolder.trashId);
    final selectedTrash = tester.widget<Text>(find.text('Trash'));
    expect(selectedTrash.style?.color, trashColor);
    expect(
      find.ancestor(
        of: find.text('Discarded chapter'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byIcon(Icons.note_add_outlined),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'book row selects across its full width while the overlaid edit button stays separate',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = LibraryViewModel(_LibraryRepository());
      await tester.pumpWidget(_app(library: library));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fiction'));
      await tester.pumpAndSettle();
      expect(library.selectedBook?.id, 'book-b');

      await tester.tap(find.text('Book B').first);
      await tester.pumpAndSettle();
      final bookRow = find
          .ancestor(
            of: find.text('Book A').last,
            matching: find.byType(InkWell),
          )
          .first;
      final rowRect = tester.getRect(bookRow);
      final editRect = tester.getRect(find.byIcon(Icons.edit_outlined).first);
      expect(rowRect.contains(editRect.center), isTrue);
      await tester.tapAt(Offset(rowRect.right - 2, rowRect.bottom - 2));
      await tester.pumpAndSettle();
      expect(library.selectedBook?.id, 'Default');

      await tester.tap(find.text('Book A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(library.selectedBook?.id, 'Default');
    },
  );

  testWidgets('wide layout docks the shared sidebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final sidebar = tester.getRect(find.byType(WorkspaceSidebar));
    final expandButton = tester.getRect(
      find.ancestor(
        of: find.byIcon(Icons.unfold_less),
        matching: find.byType(IconButton),
      ),
    );
    final newChapterButton = tester.getRect(
      find.ancestor(
        of: find.byIcon(Icons.note_add_outlined),
        matching: find.byType(IconButton),
      ),
    );
    expect(newChapterButton.left - expandButton.right, 4);
    expect(
      (expandButton.center.dx + newChapterButton.center.dx) / 2,
      closeTo(sidebar.center.dx, 0.01),
    );

    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand all'), findsOneWidget);
    expect(find.text('Volume A'), findsOneWidget);
  });

  testWidgets(
    'chapter content has equal insets and preview removes line breaks and indent characters',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final chapterInkWell = find
          .ancestor(of: find.text('Chapter A'), matching: find.byType(InkWell))
          .first;
      final padding = tester.widget<InkWell>(chapterInkWell).child! as Padding;
      final insets = padding.padding.resolve(TextDirection.ltr);
      expect(insets.left, insets.right);
      final preview = tester.widget<Text>(
        find.text('First lineSecond lineThird line'),
      );
      final metadata = tester.widget<Text>(
        find.text('2025-12-19 - 2026-01-02 - 42字'),
      );
      expect(preview.style?.fontSize, metadata.style?.fontSize);
      expect(find.text('First line\n\u3000\u3000Second line\r\n\u3000\u3000Third line'), findsNothing);
    },
  );

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

Widget _app({LibraryViewModel? library}) {
  library ??= LibraryViewModel(_LibraryRepository());
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
  _LibraryRepository({this.scrollingSections = false});

  final bool scrollingSections;

  @override
  Future<WritingLibrary> loadLibrary() async => WritingLibrary(
    folders: const [
      WritingFolder(id: 'Default', name: 'Book A', rank: 0),
      WritingFolder(id: 'book-b', name: 'Book B', rank: 1, tags: 'Fiction'),
      WritingFolder(id: WritingFolder.trashId, name: 'Trash', rank: 2),
    ],
    categories: [
      const WritingCategory(
        id: 'volume-a',
        folderId: 'Default',
        name: 'Volume A',
        rank: 0,
        collapsed: false,
      ),
      if (scrollingSections)
        const WritingCategory(
          id: 'volume-b',
          folderId: 'Default',
          name: 'Volume B',
          rank: 1,
          collapsed: false,
        ),
    ],
    articles: [
      ArticleSummary(
        id: 'article',
        title: 'Chapter A',
        summary: 'First line\n\u3000\u3000Second line\r\n\u3000\u3000Third line',
        folderId: 'Default',
        categoryId: 'volume-a',
        createdAt: DateTime.utc(2025, 12, 19),
        updatedAt: DateTime.utc(2026, 1, 2),
        wordCount: 42,
      ),
      ArticleSummary(
        id: 'trashed',
        title: 'Discarded chapter',
        summary: 'Discarded content',
        folderId: WritingFolder.trashId,
        categoryId: 'volume-a',
        createdAt: DateTime.utc(2025, 12, 19),
        updatedAt: DateTime.utc(2026, 1, 2),
        wordCount: 17,
      ),
      if (scrollingSections)
        for (var index = 0; index < 14; index++)
          ArticleSummary(
            id: 'a-$index',
            title: 'A chapter $index',
            summary: 'Preview',
            folderId: 'Default',
            categoryId: 'volume-a',
            createdAt: DateTime.utc(2025, 12, 19),
            updatedAt: DateTime.utc(2026, 1, 2),
            wordCount: 7,
          ),
      if (scrollingSections)
        for (var index = 0; index < 14; index++)
          ArticleSummary(
            id: 'b-$index',
            title: 'B chapter $index',
            summary: 'Preview',
            folderId: 'Default',
            categoryId: 'volume-b',
            createdAt: DateTime.utc(2025, 12, 19),
            updatedAt: DateTime.utc(2026, 1, 2),
            wordCount: 7,
          ),
    ],
  );

  @override
  Future<WritingArticle> getArticle(String id) async {
    final summary = (await loadLibrary()).articles.singleWhere(
      (article) => article.id == id,
    );
    return WritingArticle(
      id: summary.id,
      title: summary.title,
      content: id == 'trashed' ? 'Discarded content' : 'Hello',
      summary: summary.summary,
      folderId: summary.folderId,
      categoryId: summary.categoryId,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      wordCount: summary.wordCount,
    );
  }

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
  Future<void> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  }) async {}

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

  @override
  Future<SystemFont?> importFont(String sourcePath) async => null;
}
