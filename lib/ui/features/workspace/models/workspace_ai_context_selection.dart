import 'package:flutter/foundation.dart';

import '../../../../domain/models/purewriter_models.dart';

/// One chapter pinned as AI context (id + display title at selection time).
class WorkspaceAiContextArticle {
  const WorkspaceAiContextArticle({required this.id, required this.title});

  final String id;
  final String title;
}

/// Mutable set of chapters the user selected in the sidebar for AI context.
class WorkspaceAiContextSelection extends ChangeNotifier {
  final Map<String, String> _titlesById = {};

  List<WorkspaceAiContextArticle> get articles {
    return [
      for (final entry in _titlesById.entries)
        WorkspaceAiContextArticle(id: entry.key, title: entry.value),
    ];
  }

  bool contains(String articleId) => _titlesById.containsKey(articleId);

  void toggle(ArticleSummary chapter, {required String displayTitle}) {
    if (_titlesById.containsKey(chapter.id)) {
      _titlesById.remove(chapter.id);
    } else {
      _titlesById[chapter.id] = displayTitle;
    }
    notifyListeners();
  }

  void remove(String articleId) {
    if (_titlesById.remove(articleId) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_titlesById.isEmpty) return;
    _titlesById.clear();
    notifyListeners();
  }
}
