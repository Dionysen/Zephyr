import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';

import '../support/ai_chat_repository_test_stubs.dart';
import '../support/article_editor_state_repository_test_stubs.dart';
import '../support/sidebar_volume_expansion_repository_test_stubs.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/workspace/views/library_search_sheet.dart';

void main() {
  testWidgets('search sheet finds content and opens the matching chapter', (
    tester,
  ) async {
    final repository = _SearchRepository();
    final model = LibraryViewModel(repository);
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLibrarySearchSheet(context, model: model),
              child: const Text('Open search'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilterChip).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pump(const Duration(milliseconds: 251));
    await tester.pumpAndSettle();

    expect(repository.searchCalls, 1);
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(model.article?.id, 'article');
    expect(model.pendingSearchHighlight?.articleId, 'article');
    expect(model.pendingSearchHighlight?.query, 'alpha');
    expect(model.pendingSearchHighlight?.hasContentRange, isTrue);
  });
}

class _SearchRepository
    with
        AiChatRepositoryMethods,
        ArticleEditorStateRepositoryMethods,
        SidebarVolumeExpansionRepositoryMethods
    implements WritingLibraryRepository {
  static final article = WritingArticle(
    id: 'article',
    title: 'Chapter',
    summary: '',
    folderId: 'book',
    categoryId: null,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    wordCount: 3,
    content: 'alpha beta alpha',
  );
  int searchCalls = 0;

  @override
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  }) async {
    searchCalls++;
    return [article];
  }

  @override
  Future<WritingArticle> getArticle(String id) async => article;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
