import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/article_text_search.dart';

void main() {
  group('searchArticles', () {
    test('returns empty for blank query', () {
      final results = searchArticles(
        articles: [
          (
            id: 'a',
            title: 'Hello',
            content: 'world',
            folderId: 'book',
            categoryId: null,
          ),
        ],
        query: '   ',
      );
      expect(results, isEmpty);
    });

    test('finds case-insensitive content matches with utf-16 offsets', () {
      const content = 'Hello Alpha hello';
      final results = searchArticles(
        articles: [
          (
            id: 'a',
            title: 'Chapter',
            content: content,
            folderId: 'book',
            categoryId: 'v1',
          ),
        ],
        query: 'HELLO',
      );
      final contentHits =
          results.where((match) => !match.isTitleOnly).toList();
      expect(contentHits, hasLength(2));
      expect(contentHits[0].contentStart, 0);
      expect(contentHits[0].contentEnd, 5);
      expect(contentHits[1].contentStart, 12);
      expect(contentHits[1].contentEnd, 17);
      expect(
        content.substring(
          contentHits[0].contentStart!,
          contentHits[0].contentEnd!,
        ),
        'Hello',
      );
    });

    test('emits a title-only match when title contains query', () {
      final results = searchArticles(
        articles: [
          (
            id: 'a',
            title: 'River Song',
            content: 'plain body',
            folderId: 'book',
            categoryId: null,
          ),
        ],
        query: 'river',
      );
      expect(results, hasLength(1));
      expect(results.single.isTitleOnly, isTrue);
      expect(results.single.snippet, 'River Song');
      expect(results.single.snippetHighlightStart, 0);
      expect(results.single.snippetHighlightEnd, 5);
    });

    test('builds a snippet with ellipsis and highlight range', () {
      final content = '${'x' * 40}needle${'y' * 40}';
      final results = searchArticles(
        articles: [
          (
            id: 'a',
            title: 'T',
            content: content,
            folderId: 'book',
            categoryId: null,
          ),
        ],
        query: 'needle',
        snippetRadius: 4,
      );
      final hit = results.singleWhere((match) => !match.isTitleOnly);
      expect(hit.snippet.startsWith('…'), isTrue);
      expect(hit.snippet.endsWith('…'), isTrue);
      expect(
        hit.snippet.substring(
          hit.snippetHighlightStart,
          hit.snippetHighlightEnd,
        ),
        'needle',
      );
    });

    test('collapses newlines inside snippets', () {
      final results = searchArticles(
        articles: [
          (
            id: 'a',
            title: 'T',
            content: 'before\nmatch\nafter',
            folderId: 'book',
            categoryId: null,
          ),
        ],
        query: 'match',
      );
      final hit = results.singleWhere((match) => !match.isTitleOnly);
      expect(hit.snippet.contains('\n'), isFalse);
      expect(
        hit.snippet.substring(
          hit.snippetHighlightStart,
          hit.snippetHighlightEnd,
        ),
        'match',
      );
    });

    test('sorts by book, volume, chapter, title hit, then offset', () {
      final matches = [
        const ArticleSearchMatch(
          articleId: 'c2',
          title: 'C2',
          folderId: 'b2',
          categoryId: 'v2',
          query: 'x',
          contentStart: 0,
          contentEnd: 1,
        ),
        const ArticleSearchMatch(
          articleId: 'c1',
          title: 'C1',
          folderId: 'b1',
          categoryId: null,
          query: 'x',
          contentStart: 4,
          contentEnd: 5,
        ),
        const ArticleSearchMatch(
          articleId: 'c1',
          title: 'C1',
          folderId: 'b1',
          categoryId: null,
          query: 'x',
        ),
        const ArticleSearchMatch(
          articleId: 'c0',
          title: 'C0',
          folderId: 'b1',
          categoryId: 'v0',
          query: 'x',
          contentStart: 0,
          contentEnd: 1,
        ),
      ];
      final sorted = sortSearchMatchesByManuscriptOrder(
        matches,
        manuscriptSearchOrderFromLibrary(
          folders: [(id: 'b1'), (id: 'b2')],
          categories: [
            (id: 'v0', folderId: 'b1'),
            (id: 'v2', folderId: 'b2'),
          ],
          articles: [(id: 'c0'), (id: 'c1'), (id: 'c2')],
        ),
      );
      // Unfiled chapters (c1) sort above volume chapters (c0) in the same book.
      expect(
        sorted.map((m) => '${m.articleId}:${m.isTitleOnly}:${m.contentStart}'),
        [
          'c1:true:null',
          'c1:false:4',
          'c0:false:0',
          'c2:false:0',
        ],
      );
    });
  });
}
