import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';

import '../support/ai_chat_repository_test_stubs.dart';
import '../support/article_editor_state_repository_test_stubs.dart';
import '../support/sidebar_volume_expansion_repository_test_stubs.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/editor/views/article_history_sheet.dart';

void main() {
  testWidgets(
    'history restore requires confirmation and passes the selected revision',
    (tester) async {
      final repository = _HistoryRepository();
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
                onPressed: () => showArticleHistorySheet(
                  context,
                  model: model,
                  articleId: 'article',
                ),
                child: const Text('Open history'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open history'));
      await tester.pumpAndSettle();
      expect(find.text('old words'), findsOneWidget);

      await tester.tap(find.text('old words'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.restoreCalls, 0);

      await tester.tap(find.text('old words'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.restoreCalls, 1);
      expect(repository.restoredArticleId, 'article');
      expect(repository.restoredAt, _HistoryRepository.revision.createdAt);
    },
  );
}

class _HistoryRepository
    with
        AiChatRepositoryMethods,
        ArticleEditorStateRepositoryMethods,
        SidebarVolumeExpansionRepositoryMethods
    implements WritingLibraryRepository {
  static final revision = ArticleHistory(
    createdAt: DateTime.utc(2026, 1, 2),
    content: 'old words',
  );
  int restoreCalls = 0;
  String? restoredArticleId;
  DateTime? restoredAt;

  @override
  Future<List<ArticleHistory>> listHistory(String articleId) async => [
    revision,
  ];

  @override
  Future<void> restoreHistory({
    required String articleId,
    required DateTime createdAt,
  }) async {
    restoreCalls++;
    restoredArticleId = articleId;
    restoredAt = createdAt;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
