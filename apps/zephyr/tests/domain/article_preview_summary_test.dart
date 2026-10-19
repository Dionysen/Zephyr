import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/article_preview_summary.dart';

void main() {
  test('preview trims surrounding whitespace and joins mixed newlines', () {
    expect(
      articlePreviewSummary('  First\r\n\nsecond\rthird  '),
      'First second third',
    );
  });

  test('preview keeps at most 200 Unicode code points', () {
    final content = '${List.filled(199, '😀').join()}终more';
    final summary = articlePreviewSummary(content);

    expect(summary.runes.length, 200);
    expect(summary.endsWith('终'), isTrue);
  });

  test('preview of whitespace-only content is empty', () {
    expect(articlePreviewSummary(' \n\r  '), isEmpty);
  });
}
