import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/use_cases/article_text_search.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';

enum LibrarySearchScope {
  currentArticle,
  currentVolume,
  currentBook,
  allBooks,
}

Future<void> showLibrarySearchSheet(
  BuildContext context, {
  required LibraryViewModel model,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  model.collapseSidebar();
  ZephyrSwipeDrawer.maybeOf(context)?.close();
  final scaffold = Scaffold.maybeOf(context);
  if (scaffold != null && scaffold.isDrawerOpen) {
    scaffold.closeDrawer();
  }
  if (!context.mounted) return;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      minChildSize: 0.45,
      maxChildSize: 1,
      builder: (context, scrollController) => _LibrarySearchSheet(
        model: model,
        scrollController: scrollController,
      ),
    ),
  );
}

class _LibrarySearchSheet extends StatefulWidget {
  const _LibrarySearchSheet({
    required this.model,
    required this.scrollController,
  });

  final LibraryViewModel model;
  final ScrollController scrollController;

  @override
  State<_LibrarySearchSheet> createState() => _LibrarySearchSheetState();
}

class _LibrarySearchSheetState extends State<_LibrarySearchSheet> {
  final _queryController = TextEditingController();
  final _queryFocus = FocusNode();
  var _scope = LibrarySearchScope.currentBook;
  var _query = '';
  var _loading = false;
  var _searched = false;
  List<ArticleSearchMatch> _results = const [];
  Timer? _debounce;
  int _searchGen = 0;

  @override
  void initState() {
    super.initState();
    if (widget.model.article == null) {
      _scope = LibrarySearchScope.currentBook;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _queryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = value);
      unawaited(_runSearch());
    });
  }

  void _onScopeChanged(LibrarySearchScope scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    unawaited(_runSearch());
  }

  Future<void> _runSearch() async {
    final query = _query.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
        _searched = false;
      });
      return;
    }

    final gen = ++_searchGen;
    setState(() {
      _loading = true;
      _searched = true;
    });

    try {
      final articles = await _loadScopedArticles();
      if (!mounted || gen != _searchGen) return;
      final matches = searchArticles(
        articles: [
          for (final article in articles)
            (
              id: article.id,
              title: article.title,
              content: article.content,
              folderId: article.folderId,
              categoryId: article.categoryId,
            ),
        ],
        query: query,
      );
      if (!mounted || gen != _searchGen) return;
      final library = widget.model.library;
      final ordered = library == null
          ? matches
          : sortSearchMatchesByManuscriptOrder(
              matches,
              manuscriptSearchOrderFromLibrary(
                folders: [
                  for (final book in library.folders) (id: book.id),
                ],
                categories: [
                  for (final volume in library.categories)
                    (id: volume.id, folderId: volume.folderId),
                ],
                articles: [
                  for (final chapter in library.articles) (id: chapter.id),
                ],
              ),
            );
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _results = ordered;
        _loading = false;
      });
    } on Object {
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  Future<List<WritingArticle>> _loadScopedArticles() async {
    final model = widget.model;
    final book = model.selectedBook;
    final article = model.article;

    switch (_scope) {
      case LibrarySearchScope.currentArticle:
        if (article == null) return const [];
        return model.loadArticlesForSearch(articleId: article.id);
      case LibrarySearchScope.currentVolume:
        if (book == null || article == null) return const [];
        final categoryId = article.categoryId;
        if (categoryId == null) {
          return model.loadArticlesForSearch(
            folderId: book.id,
            unfiledOnly: true,
          );
        }
        return model.loadArticlesForSearch(
          folderId: book.id,
          categoryId: categoryId,
        );
      case LibrarySearchScope.currentBook:
        if (book == null) return const [];
        return model.loadArticlesForSearch(
          folderId: book.id,
          includeTrash: book.isTrash,
        );
      case LibrarySearchScope.allBooks:
        return model.loadArticlesForSearch();
    }
  }

  Future<void> _openMatch(ArticleSearchMatch match) async {
    Navigator.of(context).pop();
    await widget.model.requestSearchJump(
      articleId: match.articleId,
      query: match.query,
      contentStart: match.contentStart,
      contentEnd: match.contentEnd,
    );
  }

  String _matchPathTitle(ArticleSearchMatch match, AppLocalizations l10n) {
    final library = widget.model.library;
    final bookName = library?.folders
            .where((book) => book.id == match.folderId)
            .map((book) => book.name)
            .firstOrNull ??
        l10n.untitled;
    final volumeName = match.categoryId == null
        ? l10n.unfiledVolume
        : library?.categories
                .where((volume) => volume.id == match.categoryId)
                .map((volume) => volume.name)
                .firstOrNull ??
            l10n.unfiledVolume;
    final chapterName = match.title.isEmpty ? l10n.untitled : match.title;
    return '$bookName · $volumeName · $chapterName';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasArticle = widget.model.article != null;

    return ZephyrBottomSheet.listTheme(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ZephyrBottomSheet.titlePadding,
            child: Text(
              l10n.searchSheetTitle,
              style: ZephyrBottomSheet.titleStyle(theme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: TextField(
              controller: _queryController,
              focusNode: _queryFocus,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => unawaited(_runSearch()),
              decoration: InputDecoration(
                hintText: l10n.searchSheetHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in [
                  (
                    scope: LibrarySearchScope.currentArticle,
                    label: l10n.searchScopeArticle,
                    enabled: hasArticle,
                  ),
                  (
                    scope: LibrarySearchScope.currentVolume,
                    label: l10n.searchScopeVolume,
                    enabled: hasArticle,
                  ),
                  (
                    scope: LibrarySearchScope.currentBook,
                    label: l10n.searchScopeBook,
                    enabled: true,
                  ),
                  (
                    scope: LibrarySearchScope.allBooks,
                    label: l10n.searchScopeAllBooks,
                    enabled: true,
                  ),
                ])
                  FilterChip(
                    label: Text(
                      option.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    selected: _scope == option.scope,
                    showCheckmark: false,
                    visualDensity: const VisualDensity(
                      horizontal: -3,
                      vertical: -3,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: context.zephyrBorderRadius,
                    ),
                    onSelected: !option.enabled
                        ? null
                        : (_) => _onScopeChanged(option.scope),
                  ),
              ],
            ),
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: _buildResults(theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme, AppLocalizations l10n) {
    if (!_searched || _query.trim().isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.searchSheetEmptyQuery,
            style: ZephyrBottomSheet.bodyStyle(theme),
          ),
        ],
      );
    }
    if (!_loading && _results.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.searchSheetNoResults,
            style: ZephyrBottomSheet.bodyStyle(theme),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: widget.scrollController,
      itemCount: _results.length,
      separatorBuilder: (context, _) => ZephyrBottomSheet.rowDivider(context),
      itemBuilder: (context, index) {
        final match = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          title: Text(
            _matchPathTitle(match, l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _HighlightedSnippet(
            text: match.snippet,
            highlightStart: match.snippetHighlightStart,
            highlightEnd: match.snippetHighlightEnd,
            style: ZephyrBottomSheet.rowSubtitleStyle(theme),
            highlightStyle: ZephyrBottomSheet.rowSubtitleStyle(theme)?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              backgroundColor: theme.colorScheme.tertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => unawaited(_openMatch(match)),
        );
      },
    );
  }
}

class _HighlightedSnippet extends StatelessWidget {
  const _HighlightedSnippet({
    required this.text,
    required this.highlightStart,
    required this.highlightEnd,
    required this.style,
    required this.highlightStyle,
  });

  final String text;
  final int highlightStart;
  final int highlightEnd;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  @override
  Widget build(BuildContext context) {
    final start = highlightStart.clamp(0, text.length);
    final end = highlightEnd.clamp(0, text.length);
    if (start >= end) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    }
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: highlightStyle,
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
