import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
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
    updatedAt: DateTime.utc(2026),
  );
  @override
  Future<WritingLibrary> loadLibrary() async => WritingLibrary(
    folders: const [WritingFolder(id: 'Default', name: 'Default', rank: 0)],
    categories: const [],
    articles: [
      ArticleSummary(
        id: saved.id,
        title: saved.title,
        summary: '',
        folderId: saved.folderId,
        categoryId: null,
        updatedAt: saved.updatedAt,
      ),
    ],
  );
  @override
  Future<WritingArticle> getArticle(String id) async => saved;
  @override
  Future<WritingArticle> createArticle({required String folderId}) async =>
      saved;
  @override
  Future<void> saveArticle(WritingArticle article) async {
    saved = article;
  }

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
