import 'package:flutter/foundation.dart';

import '../../../../domain/models/purewriter_models.dart';
import 'workspace_ai_composer_document.dart';

/// One chapter pinned as AI context (id + display title at selection time).
class WorkspaceAiContextArticle {
  const WorkspaceAiContextArticle({required this.id, required this.title});

  final String id;
  final String title;
}

/// Sidebar chapter picks for AI chat — inserts inline capsules in the composer.
class WorkspaceAiContextSelection extends ChangeNotifier {
  WorkspaceAiComposerController? _composer;

  void attachComposer(WorkspaceAiComposerController composer) {
    if (_composer == composer) return;
    _composer?.removeListener(notifyListeners);
    _composer = composer;
    _composer!.addListener(notifyListeners);
  }

  void detachComposer(WorkspaceAiComposerController composer) {
    if (_composer != composer) return;
    _composer!.removeListener(notifyListeners);
    _composer = null;
  }

  List<WorkspaceAiContextArticle> get articles {
    final composer = _composer;
    if (composer == null) return const [];
    return [
      for (final ref in composer.orderedArticles())
        WorkspaceAiContextArticle(id: ref.articleId, title: ref.title),
    ];
  }

  bool contains(String articleId) => _composer?.containsArticle(articleId) ?? false;

  void toggle(ArticleSummary chapter, {required String displayTitle}) {
    final composer = _composer;
    if (composer == null) return;
    if (composer.containsArticle(chapter.id)) {
      composer.removeAllArticles(chapter.id);
    } else {
      composer.insertArticleAtFocus(chapter.id, displayTitle);
    }
    notifyListeners();
  }

  void remove(String articleId) {
    _composer?.removeAllArticles(articleId);
    notifyListeners();
  }

  void clear() {
    _composer?.clear();
    notifyListeners();
  }
}
