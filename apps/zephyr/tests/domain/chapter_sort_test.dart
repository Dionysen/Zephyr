import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/chapter_sort_mode.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/use_cases/chapter_sort.dart';

ArticleSummary _chapter({
  required String id,
  String title = '',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2024, 1, 1);
  return ArticleSummary(
    id: id,
    title: title,
    summary: '',
    folderId: 'book',
    categoryId: 'vol',
    createdAt: created,
    updatedAt: updatedAt ?? created,
    wordCount: 0,
  );
}

void main() {
  group('sortArticleSummaries', () {
    test('manual preserves input order', () {
      final input = [
        _chapter(id: 'c', title: 'C'),
        _chapter(id: 'a', title: 'A'),
        _chapter(id: 'b', title: 'B'),
      ];
      final sorted = sortArticleSummaries(input, ChapterSortMode.manual);
      expect(sorted.map((e) => e.id), ['c', 'a', 'b']);
    });

    test('title ascending is case-insensitive', () {
      final input = [
        _chapter(id: '1', title: 'banana'),
        _chapter(id: '2', title: 'Apple'),
        _chapter(id: '3', title: 'cherry'),
      ];
      final sorted = sortArticleSummaries(input, ChapterSortMode.titleAsc);
      expect(sorted.map((e) => e.id), ['2', '1', '3']);
    });

    test('title descending', () {
      final input = [
        _chapter(id: '1', title: 'a'),
        _chapter(id: '2', title: 'c'),
        _chapter(id: '3', title: 'b'),
      ];
      final sorted = sortArticleSummaries(input, ChapterSortMode.titleDesc);
      expect(sorted.map((e) => e.id), ['2', '3', '1']);
    });

    test('created time ascending and descending', () {
      final input = [
        _chapter(id: 'mid', createdAt: DateTime.utc(2024, 2, 1)),
        _chapter(id: 'old', createdAt: DateTime.utc(2024, 1, 1)),
        _chapter(id: 'new', createdAt: DateTime.utc(2024, 3, 1)),
      ];
      expect(
        sortArticleSummaries(input, ChapterSortMode.createdAsc)
            .map((e) => e.id),
        ['old', 'mid', 'new'],
      );
      expect(
        sortArticleSummaries(input, ChapterSortMode.createdDesc)
            .map((e) => e.id),
        ['new', 'mid', 'old'],
      );
    });

    test('updated time sorting', () {
      final input = [
        _chapter(
          id: 'a',
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 5, 1),
        ),
        _chapter(
          id: 'b',
          createdAt: DateTime.utc(2024, 2, 1),
          updatedAt: DateTime.utc(2024, 3, 1),
        ),
      ];
      expect(
        sortArticleSummaries(input, ChapterSortMode.updatedAsc)
            .map((e) => e.id),
        ['b', 'a'],
      );
      expect(
        sortArticleSummaries(input, ChapterSortMode.updatedDesc)
            .map((e) => e.id),
        ['a', 'b'],
      );
    });

    test('ties break by id for stability', () {
      final t = DateTime.utc(2024, 1, 1);
      final input = [
        _chapter(id: 'z', title: 'Same', createdAt: t),
        _chapter(id: 'a', title: 'Same', createdAt: t),
      ];
      expect(
        sortArticleSummaries(input, ChapterSortMode.titleAsc).map((e) => e.id),
        ['a', 'z'],
      );
    });
  });

  group('ChapterSortMode.fromStorageId', () {
    test('parses known ids and falls back to manual', () {
      expect(
        ChapterSortMode.fromStorageId('titleAsc'),
        ChapterSortMode.titleAsc,
      );
      expect(ChapterSortMode.fromStorageId(null), ChapterSortMode.manual);
      expect(ChapterSortMode.fromStorageId('nope'), ChapterSortMode.manual);
    });
  });
}
