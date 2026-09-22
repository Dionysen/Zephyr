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
}
