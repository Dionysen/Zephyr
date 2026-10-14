import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/l10n/app_localizations_en.dart';
import 'package:zephyr/domain/models/chapter_sort_mode.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/models/workspace_layout.dart';
import 'package:zephyr/domain/repositories/workspace_layout_repository.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
import 'package:zephyr/domain/use_cases/article_preview_summary.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';

void main() {
  test('loads the first article and saves its changed text', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(repository);
    await model.load();
    model.updateContent('Updated text');
    await model.save();
    expect(model.article?.id, 'article');
    expect(repository.saved.content, 'Updated text');
    expect(repository.saved.wordCount, 'Updated text'.runes.length);
    expect(repository.saved.createdAt, DateTime.utc(2025));
  });

  test('flushPending saves dirty content before switching chapters', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(repository);
    await model.load();
    model.updateContent('Unsaved on A');
    await model.selectArticle('article-b');
    expect(repository.saved.content, 'Unsaved on A');
    expect(model.article?.id, 'article-b');
  });

  test('save refreshes sidebar preview when leading text changes', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(repository);
    await model.load();
    final before = model.library!.articles.singleWhere((a) => a.id == 'article');
    expect(before.summary, isNot(contains('Brand new opening')));

    model.updateContent('Brand new opening\n\nRest of chapter');
    await model.save();

    final after = model.library!.articles.singleWhere((a) => a.id == 'article');
    expect(after.summary, 'Brand new opening Rest of chapter');
    expect(model.article?.summary, after.summary);
  });

  test('save does not rewrite sidebar preview when only the tail changes', () async {
    final head = 'A' * 200;
    final repository = FakeLibraryRepository()
      ..saved = WritingArticle(
        id: 'article',
        title: 'Article',
        content: '${head}old-tail',
        summary: head,
        folderId: 'Default',
        categoryId: null,
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2026),
        wordCount: head.length + 8,
      );
    final model = LibraryViewModel(repository);
    await model.load();

    model.updateContent('${head}new-tail-changed');
    await model.save();

    final after = model.library!.articles.singleWhere((a) => a.id == 'article');
    expect(after.summary, head);
    expect(after.summary, articlePreviewSummary('${head}new-tail-changed'));
  });

  test('switching books selects only that book chapter', () async {
    final model = LibraryViewModel(FakeLibraryRepository());
    await model.load();

    await model.selectBook('book-b');

    expect(model.selectedBook?.name, 'Book B');
    expect(model.article?.id, 'article-b');
  });

  test('sidebar visibility is an explicit presentation state', () {
    final model = LibraryViewModel(FakeLibraryRepository());

    expect(model.isSidebarExpanded, isTrue);
    model.toggleSidebar();
    expect(model.isSidebarExpanded, isFalse);
    model.toggleSidebar();
    expect(model.isSidebarExpanded, isTrue);
  });

  test('reorder mode toggles and clears in trash', () async {
    final model = LibraryViewModel(FakeLibraryRepository());
    await model.load();

    expect(model.isReorderMode, isFalse);
    model.toggleReorderMode();
    expect(model.isReorderMode, isTrue);
    model.toggleReorderMode();
    expect(model.isReorderMode, isFalse);

    model.toggleReorderMode();
    await model.selectBook(WritingFolder.trashId);
    expect(model.isReorderMode, isFalse);
  });

  test('chapter sort mode exits reorder and blocks drag until manual', () async {
    final model = LibraryViewModel(FakeLibraryRepository());
    await model.load();

    expect(model.chapterSortMode, ChapterSortMode.manual);
    model.toggleReorderMode();
    expect(model.isReorderMode, isTrue);

    model.setChapterSortMode(ChapterSortMode.titleAsc);
    expect(model.chapterSortMode, ChapterSortMode.titleAsc);
    expect(model.isReorderMode, isFalse);

    model.toggleReorderMode();
    expect(model.isReorderMode, isFalse);

    model.setChapterSortMode(ChapterSortMode.manual);
    expect(model.chapterSortMode, ChapterSortMode.manual);
    model.toggleReorderMode();
    expect(model.isReorderMode, isTrue);
  });

  test('volume drag collapses all volumes then restores expand state', () async {
    final model = LibraryViewModel(FakeLibraryRepository());
    await model.load();

    expect(model.isVolumeExpanded('volume-a'), isTrue);
    model.beginVolumeReorderDrag();
    expect(model.isVolumeExpanded('volume-a'), isFalse);
    model.endVolumeReorderDrag();
    expect(model.isVolumeExpanded('volume-a'), isTrue);

    model.toggleVolume('volume-a');
    expect(model.isVolumeExpanded('volume-a'), isFalse);
    model.beginVolumeReorderDrag();
    expect(model.isVolumeExpanded('volume-a'), isFalse);
    model.endVolumeReorderDrag();
    expect(model.isVolumeExpanded('volume-a'), isFalse);
  });

  test('remembers the last opened library folder', () async {
    final library = FakeLibraryRepository();
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(library, layoutRepository: layout);

    expect(model.needsLibrarySetup, isTrue);
    await model.openLibrary('/writing/book', bookmark: 'bookmark-data');

    expect(library.openedRoot, '/writing/book');
    expect(layout.layout.lastLibraryRoot, '/writing/book');
    expect(layout.layout.lastLibraryBookmark, 'bookmark-data');
    expect(model.needsLibrarySetup, isFalse);
    expect(model.libraryName, 'book');
    expect(model.libraries, hasLength(1));
    expect(model.libraries.single.displayName, 'book');
    expect(model.activeLibraryId, model.libraries.single.id);
  });

  test('reselecting the same directory keeps its identity', () async {
    final library = FakeLibraryRepository();
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(library, layoutRepository: layout);
    await model.openLibrary('/writing/book');
    final id = model.libraries.single.id;

    await model.openLibrary('/writing/book');

    expect(model.libraries, hasLength(1));
    expect(model.libraries.single.id, id);
    expect(model.libraries.single.displayName, 'book');
    expect(model.libraries.single.rootPath, '/writing/book');
    expect(model.displayLibraryName(AppLocalizationsEn()), 'book');
    expect(layout.layout.libraries.single.displayName, 'book');
  });

  test('choosing another directory replaces the current library', () async {
    final library = FakeLibraryRepository();
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(library, layoutRepository: layout);
    await model.openLibrary('/writing/a');
    final previousId = model.activeLibraryId;
    await model.openLibrary('/writing/b');

    expect(model.libraries, hasLength(1));
    expect(model.libraries.single.rootPath, '/writing/b');
    expect(model.activeLibraryId, isNot(previousId));
    expect(model.activeLibraryId, model.libraries.single.id);
    expect(layout.layout.libraries, hasLength(1));
    expect(layout.layout.lastLibraryRoot, '/writing/b');
  });

  test('loads only the active directory from an older library list', () async {
    final library = FakeLibraryRepository();
    await library.openLibrary('/writing/second');
    final layout = FakeLayoutRepository(
      const WorkspaceLayout(
        sidebarWidth: WorkspaceLayout.defaultSidebarWidth,
        activeLibraryId: 'second',
        libraries: [
          LibraryRegistryEntry(
            id: 'first',
            displayName: 'Old alias',
            rootPath: '/writing/first',
          ),
          LibraryRegistryEntry(
            id: 'second',
            displayName: 'Another alias',
            rootPath: '/writing/second',
          ),
        ],
      ),
    );
    final model = LibraryViewModel(library, layoutRepository: layout);

    await model.load();

    expect(model.libraries, hasLength(1));
    expect(model.libraries.single.id, 'second');
    expect(model.displayLibraryName(AppLocalizationsEn()), 'second');
    expect(model.activeLibraryId, 'second');
  });

  test('opens a temporary library when none is open yet', () async {
    final library = FakeLibraryRepository();
    final model = LibraryViewModel(library);

    await model.load();

    expect(library.openedRoot, '/tmp/zephyr-temporary-library');
    expect(model.needsLibrarySetup, isTrue);
    expect(
      model.displayLibraryName(AppLocalizationsEn()),
      'Temporary library',
    );
    expect(model.error, isNull);
  });

  test('loads a previously saved sidebar width', () async {
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: FakeLayoutRepository(
        const WorkspaceLayout(sidebarWidth: 412),
      ),
    );

    await model.load();

    expect(model.sidebarWidth, 412);
  });

  test(
    'toggleAllVolumes expands or collapses every volume in the book',
    () async {
      final model = LibraryViewModel(FakeLibraryRepository());
      await model.load();

      expect(model.areAllVolumesExpanded, isTrue);
      model.toggleAllVolumes();
      expect(model.areAllVolumesExpanded, isFalse);
      expect(model.isVolumeExpanded('volume-a'), isFalse);
      model.toggleAllVolumes();
      expect(model.areAllVolumesExpanded, isTrue);
    },
  );

  test('restores selected book, article, and volume expand state', () async {
    final layout = FakeLayoutRepository(
      const WorkspaceLayout(
        sidebarWidth: 334,
        selectedBookId: 'book-b',
        selectedArticleId: 'article-b',
        expandedVolumesByBook: {
          'book-b': <String>[],
        },
        sidebarScrollOffsetByBook: {'book-b': 42},
      ),
    );
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );

    await model.load();

    expect(model.selectedBook?.id, 'book-b');
    expect(model.article?.id, 'article-b');
    expect(model.isVolumeExpanded('volume-b'), isFalse);
    expect(model.sidebarScrollOffset, 42);
  });

  test('createVolume adds a volume to the selected book', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(repository);
    await model.load();

    await model.createVolume(name: 'Volume C');

    expect(
      model.library?.categories.any(
        (volume) => volume.folderId == 'Default' && volume.name == 'Volume C',
      ),
      isTrue,
    );
    expect(model.isVolumeExpanded(repository.createdVolume!.id), isTrue);
  });

  test('insertVolumeBelow places a volume after the target', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(repository);
    await model.load();

    await model.insertVolumeBelow('volume-a');

    final ids = model.library!.categories
        .where((volume) => volume.folderId == 'Default')
        .map((volume) => volume.id)
        .toList();
    expect(ids.indexOf('volume-a') + 1, ids.indexOf(repository.createdVolume!.id));
  });

  test('deleteVolume can unfile or trash chapters', () async {
    final repository = FakeLibraryRepository();
    repository.saved = WritingArticle(
      id: 'article',
      title: 'Article',
      content: '',
      summary: '',
      folderId: 'Default',
      categoryId: 'volume-a',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2026),
      wordCount: 0,
    );
    final model = LibraryViewModel(repository);
    await model.load();

    await model.deleteVolume(volumeId: 'volume-a', deleteArticles: false);
    expect(
      model.library?.categories.any((volume) => volume.id == 'volume-a'),
      isFalse,
    );
    expect(repository.saved.categoryId, isNull);

    repository.categories.insert(
      0,
      const WritingCategory(
        id: 'volume-a',
        folderId: 'Default',
        name: 'Volume A',
        rank: 0,
        collapsed: false,
      ),
    );
    repository.saved = WritingArticle(
      id: 'article',
      title: 'Article',
      content: '',
      summary: '',
      folderId: 'Default',
      categoryId: 'volume-a',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2026),
      wordCount: 0,
    );
    await model.load();
    await model.deleteVolume(volumeId: 'volume-a', deleteArticles: true);
    expect(repository.trashedArticleIds, contains('article'));
  });

  test('rename and move chapter update library state', () async {
    final repository = FakeLibraryRepository();
    repository.saved = WritingArticle(
      id: 'article',
      title: 'Article',
      content: '',
      summary: '',
      folderId: 'Default',
      categoryId: 'volume-a',
      createdAt: DateTime.utc(2025),
      updatedAt: DateTime.utc(2026),
      wordCount: 0,
    );
    final model = LibraryViewModel(repository);
    await model.load();

    await model.renameChapter(articleId: 'article', title: 'Renamed');
    expect(repository.saved.title, 'Renamed');

    await model.moveChapterToVolume(articleId: 'article', volumeId: null);
    expect(repository.saved.categoryId, isNull);
  });

  test('persists article selection and sidebar scroll offset', () async {
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );
    await model.load();

    await model.selectArticle('article-b');
    model.updateSidebarScrollOffset(96);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(layout.layout.selectedBookId, 'book-b');
    expect(layout.layout.selectedArticleId, 'article-b');
    expect(layout.layout.sidebarScrollOffsetByBook['book-b'], 96);
  });

  test('flushPending writes pending article selection without waiting', () async {
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );
    await model.load();
    // Clear any load-time layout debounce so the next write is from select.
    await model.flushPending();
    expect(layout.layout.selectedArticleId, isNot('article-b'));

    await model.selectArticle('article-b');
    // Debounce has not fired yet — still the previous chapter on disk.
    expect(layout.layout.selectedArticleId, isNot('article-b'));

    await model.flushPending();

    expect(layout.layout.selectedBookId, 'book-b');
    expect(layout.layout.selectedArticleId, 'article-b');
  });

  test('restores remembered article even when saved book id is stale', () async {
    final layout = FakeLayoutRepository(
      const WorkspaceLayout(
        sidebarWidth: 334,
        selectedBookId: 'Default',
        selectedArticleId: 'article-b',
      ),
    );
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );

    await model.load();

    expect(model.article?.id, 'article-b');
    expect(model.selectedBook?.id, 'book-b');
  });

  test('reorderBooks keeps the currently selected book', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(
      repository,
      layoutRepository: FakeLayoutRepository(WorkspaceLayout.defaults),
    );
    await model.load();
    expect(model.selectedBook?.id, 'Default');

    await model.selectBook('book-b');
    await model.reorderBooks(['book-b', 'Default']);

    expect(model.selectedBook?.id, 'book-b');
    expect(model.article?.id, 'article-b');
    expect(
      model.library!.folders.map((book) => book.id).toList(),
      ['book-b', 'Default'],
    );
  });

  test('reorderBooks keeps auto-selected first book after it moves', () async {
    final repository = FakeLibraryRepository();
    final model = LibraryViewModel(
      repository,
      layoutRepository: FakeLayoutRepository(WorkspaceLayout.defaults),
    );
    await model.load();
    expect(model.selectedBook?.id, 'Default');

    // Layout on disk still has null selection; refresh must not jump to the
    // new first book after reorder.
    await model.reorderBooks(['book-b', 'Default']);

    expect(model.selectedBook?.id, 'Default');
    expect(model.article?.id, 'article');
  });

  test('books sheet dual-column preference persists across load', () async {
    final layout = FakeLayoutRepository(WorkspaceLayout.defaults);
    final model = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );
    await model.load();
    expect(model.booksSheetDualColumn, isTrue);

    model.setBooksSheetDualColumn(false);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(layout.layout.booksSheetDualColumn, isFalse);

    final restored = LibraryViewModel(
      FakeLibraryRepository(),
      layoutRepository: layout,
    );
    await restored.load();
    expect(restored.booksSheetDualColumn, isFalse);
  });
}

class FakeLibraryRepository implements WritingLibraryRepository {
  WritingArticle saved = WritingArticle(
    id: 'article',
    title: 'Article',
    content: '',
    summary: '',
    folderId: 'Default',
    categoryId: null,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2026),
    wordCount: 0,
  );
  WritingCategory? createdVolume;
  final trashedArticleIds = <String>[];
  late final List<WritingCategory> categories = [
    const WritingCategory(
      id: 'volume-a',
      folderId: 'Default',
      name: 'Volume A',
      rank: 0,
      collapsed: false,
    ),
    const WritingCategory(
      id: 'volume-b',
      folderId: 'book-b',
      name: 'Volume B',
      rank: 0,
      collapsed: false,
    ),
  ];
  WritingArticle _secondArticle = WritingArticle(
    id: 'article-b',
    title: 'Chapter B',
    content: '',
    summary: '',
    folderId: 'book-b',
    categoryId: 'volume-b',
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2026),
    wordCount: 0,
  );
  List<WritingFolder> folders = [
    const WritingFolder(id: 'Default', name: 'Book A', rank: 0),
    const WritingFolder(id: 'book-b', name: 'Book B', rank: 1),
  ];
  @override
  Future<WritingLibrary> loadLibrary() async => WritingLibrary(
    folders: List<WritingFolder>.from(folders),
    categories: List<WritingCategory>.from(categories),
    articles: [
      ArticleSummary(
        id: saved.id,
        title: saved.title,
        summary: saved.summary,
        folderId: saved.folderId,
        categoryId: saved.categoryId,
        createdAt: saved.createdAt,
        updatedAt: saved.updatedAt,
        wordCount: saved.wordCount,
      ),
      ArticleSummary(
        id: _secondArticle.id,
        title: _secondArticle.title,
        summary: _secondArticle.summary,
        folderId: _secondArticle.folderId,
        categoryId: _secondArticle.categoryId,
        createdAt: _secondArticle.createdAt,
        updatedAt: _secondArticle.updatedAt,
        wordCount: _secondArticle.wordCount,
      ),
    ],
  );
  @override
  Future<WritingArticle> getArticle(String id) async =>
      id == saved.id ? saved : _secondArticle;

  @override
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  }) async {
    final all = [saved, _secondArticle];
    return [
      for (final article in all)
        if (articleId != null
            ? article.id == articleId
            : folderId != null && categoryId != null
                ? article.folderId == folderId &&
                    article.categoryId == categoryId
                : folderId != null && unfiledOnly
                    ? article.folderId == folderId &&
                        article.categoryId == null
                    : folderId != null
                        ? article.folderId == folderId
                        : includeTrash ||
                            article.folderId != WritingFolder.trashId)
          article,
    ];
  }
  @override
  Future<WritingArticle> createArticle({
    required String folderId,
    String? categoryId,
    String? afterArticleId,
  }) async =>
      saved;
  @override
  Future<void> saveArticle(WritingArticle article) async {
    if (article.id == _secondArticle.id) {
      _secondArticle = article;
    } else {
      saved = article;
    }
  }

  @override
  Future<void> renameArticle({
    required String articleId,
    required String title,
  }) async {
    if (saved.id == articleId) {
      saved = WritingArticle(
        id: saved.id,
        title: title,
        content: saved.content,
        summary: saved.summary,
        folderId: saved.folderId,
        categoryId: saved.categoryId,
        createdAt: saved.createdAt,
        updatedAt: saved.updatedAt,
        wordCount: saved.wordCount,
      );
    }
  }

  String? openedRoot;
  LibraryLocation? _location;

  @override
  LibraryLocation? get location => _location;
  @override
  Future<LibraryLocation> openLibrary(String rootPath) async {
    openedRoot = rootPath;
    _location = LibraryLocation(
      rootPath: rootPath,
      schema: const SchemaStatus(
        userVersion: 27,
        identityHash: 'test',
        writesAllowed: true,
      ),
    );
    return _location!;
  }

  @override
  Future<LibraryLocation> openDefaultLibrary() =>
      openLibrary('/tmp/zephyr-temporary-library');

  @override
  Future<void> closeLibrary() async {}
  @override
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
    String? afterCategoryId,
  }) async {
    createdVolume = WritingCategory(
      id: 'volume-${categories.length}',
      folderId: folderId,
      name: name,
      rank: categories.length,
      collapsed: false,
    );
    if (afterCategoryId == null) {
      categories.add(createdVolume!);
    } else {
      final index = categories.indexWhere((item) => item.id == afterCategoryId);
      categories.insert(index + 1, createdVolume!);
    }
    return createdVolume!;
  }

  @override
  Future<void> renameCategory({
    required String categoryId,
    required String name,
  }) async {
    final index = categories.indexWhere((item) => item.id == categoryId);
    if (index < 0) return;
    final old = categories[index];
    categories[index] = WritingCategory(
      id: old.id,
      folderId: old.folderId,
      name: name,
      rank: old.rank,
      collapsed: old.collapsed,
    );
  }

  @override
  Future<void> deleteCategory({
    required String categoryId,
    required bool deleteArticles,
  }) async {
    categories.removeWhere((item) => item.id == categoryId);
    if (saved.categoryId == categoryId) {
      if (deleteArticles) {
        trashedArticleIds.add(saved.id);
      } else {
        saved = WritingArticle(
          id: saved.id,
          title: saved.title,
          content: saved.content,
          summary: saved.summary,
          folderId: saved.folderId,
          categoryId: null,
          createdAt: saved.createdAt,
          updatedAt: saved.updatedAt,
          wordCount: saved.wordCount,
        );
      }
    }
  }

  @override
  Future<void> moveArticleToCategory({
    required String articleId,
    String? categoryId,
  }) async {
    if (saved.id != articleId) return;
    saved = WritingArticle(
      id: saved.id,
      title: saved.title,
      content: saved.content,
      summary: saved.summary,
      folderId: saved.folderId,
      categoryId: categoryId,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
      wordCount: saved.wordCount,
    );
  }

  @override
  Future<void> moveArticleToFolder({
    required String articleId,
    required String folderId,
  }) async {
    if (saved.id != articleId) return;
    saved = WritingArticle(
      id: saved.id,
      title: saved.title,
      content: saved.content,
      summary: saved.summary,
      folderId: folderId,
      categoryId: null,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
      wordCount: saved.wordCount,
    );
  }

  @override
  Future<void> moveCategoryToFolder({
    required String categoryId,
    required String folderId,
  }) async {
    final index = categories.indexWhere((item) => item.id == categoryId);
    if (index >= 0) {
      final old = categories[index];
      categories[index] = WritingCategory(
        id: old.id,
        folderId: folderId,
        name: old.name,
        rank: old.rank,
        collapsed: old.collapsed,
      );
    }
    if (saved.categoryId == categoryId) {
      saved = WritingArticle(
        id: saved.id,
        title: saved.title,
        content: saved.content,
        summary: saved.summary,
        folderId: folderId,
        categoryId: categoryId,
        createdAt: saved.createdAt,
        updatedAt: saved.updatedAt,
        wordCount: saved.wordCount,
      );
    }
  }

  @override
  Future<WritingFolder> convertCategoryToFolder({
    required String categoryId,
  }) async {
    final index = categories.indexWhere((item) => item.id == categoryId);
    if (index < 0) {
      throw StateError('category not found');
    }
    final volume = categories.removeAt(index);
    final folder = WritingFolder(
      id: 'book-from-$categoryId',
      name: volume.name.trim().isEmpty ? 'Untitled' : volume.name.trim(),
      rank: folders.length,
      description: '',
      tags: '',
    );
    folders.add(folder);
    if (saved.categoryId == categoryId) {
      saved = WritingArticle(
        id: saved.id,
        title: saved.title,
        content: saved.content,
        summary: saved.summary,
        folderId: folder.id,
        categoryId: null,
        createdAt: saved.createdAt,
        updatedAt: saved.updatedAt,
        wordCount: saved.wordCount,
      );
    }
    return folder;
  }

  @override
  Future<void> reorderCategories({
    required String folderId,
    required List<String> orderedIds,
  }) async {
    final byId = {for (final item in categories) item.id: item};
    final reordered = [
      for (final id in orderedIds)
        if (byId[id] != null) byId[id]!,
    ];
    final others = categories.where((item) => !orderedIds.contains(item.id));
    categories
      ..clear()
      ..addAll(reordered)
      ..addAll(others);
  }

  @override
  Future<void> reorderArticles({
    required String folderId,
    String? categoryId,
    required List<String> orderedIds,
  }) async {}

  @override
  Future<void> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  }) async {}

  @override
  Future<WritingFolder> createFolder({
    required String name,
    String description = '',
    String tags = '',
  }) async =>
      WritingFolder(
        id: 'new-book',
        name: name,
        rank: 99,
        description: description,
        tags: tags,
      );

  @override
  Future<void> deleteFolder(String folderId) async {}

  @override
  Future<void> reorderFolders({required List<String> orderedIds}) async {
    final byId = {for (final folder in folders) folder.id: folder};
    folders = [
      for (var i = 0; i < orderedIds.length; i++)
        WritingFolder(
          id: orderedIds[i],
          name: byId[orderedIds[i]]!.name,
          rank: i,
          description: byId[orderedIds[i]]!.description,
          tags: byId[orderedIds[i]]!.tags,
        ),
    ];
  }

  @override
  Future<void> trashArticle(String articleId) async {
    trashedArticleIds.add(articleId);
  }
  @override
  Future<void> restoreArticle(
    String articleId, {
    required String folderId,
  }) async {}
  @override
  Future<List<ArticleHistory>> listHistory(String articleId) async => const [];
  @override
  Future<void> restoreHistory({
    required String articleId,
    required DateTime createdAt,
  }) async {}
  @override
  Future<List<DailyWriting>> listDaily() async => const [];
  @override
  Future<Map<String, double>> readScrolls() async => const {};
  @override
  Future<void> writeScroll(String articleId, double offset) async {}
  @override
  Future<void> upsertDraft(ArticleDraft draft) async {}
  @override
  Future<void> clearDraft(String articleId) async {}
  @override
  Future<ArticleDraft?> getDraft(String articleId) async => null;
  @override
  Future<List<ArticleDraft>> listDraftsNewerThanArticles() async => const [];
  @override
  Future<List<BackupEntry>> listBackups() async => const [];
  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async =>
      BackupEntry(
        path: '/tmp/fake.pwb',
        fileName: 'fake.pwb',
        modified: DateTime.utc(2026),
        sizeBytes: 1,
        kind: kind,
      );
  @override
  Future<LibraryMergeStats> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async => LibraryMergeStats.empty;

  @override
  Future<void> pruneBackups({int keep = 25}) async {}

  @override
  Future<String> ensureCloudLibraryId() async => 'test-cloud-library-id';
}

class FakeLayoutRepository implements WorkspaceLayoutRepository {
  FakeLayoutRepository(this.layout);

  WorkspaceLayout layout;

  @override
  Future<WorkspaceLayout> load() async => layout;

  @override
  Future<void> save(WorkspaceLayout layout) async {
    this.layout = layout;
  }
}
