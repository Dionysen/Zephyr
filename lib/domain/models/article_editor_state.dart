/// Remembered plain-text editor viewport and caret for one chapter.
class ArticleEditorState {
  const ArticleEditorState({
    this.scrollOffset = 0,
    this.selectionBase = 0,
    this.selectionExtent = 0,
    required this.updatedAt,
  });

  final double scrollOffset;
  final int selectionBase;
  final int selectionExtent;
  final int updatedAt;

  ArticleEditorState copyWith({
    double? scrollOffset,
    int? selectionBase,
    int? selectionExtent,
    int? updatedAt,
  }) => ArticleEditorState(
    scrollOffset: scrollOffset ?? this.scrollOffset,
    selectionBase: selectionBase ?? this.selectionBase,
    selectionExtent: selectionExtent ?? this.selectionExtent,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'scroll': scrollOffset,
    'base': selectionBase,
    'extent': selectionExtent,
    'updatedAt': updatedAt,
  };

  static ArticleEditorState? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final scroll = raw['scroll'];
    final base = raw['base'];
    final extent = raw['extent'];
    final updatedAt = raw['updatedAt'];
    if (updatedAt is! num) return null;
    return ArticleEditorState(
      scrollOffset: scroll is num ? scroll.toDouble() : 0,
      selectionBase: base is num ? base.toInt() : 0,
      selectionExtent: extent is num ? extent.toInt() : 0,
      updatedAt: updatedAt.toInt(),
    );
  }

  /// Keeps the entry with the latest [updatedAt].
  static ArticleEditorState? merge(
    ArticleEditorState? local,
    ArticleEditorState? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;
    return remote.updatedAt >= local.updatedAt ? remote : local;
  }
}
