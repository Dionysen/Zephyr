import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/insert_timestamp_text.dart';

void main() {
  test('formats as yyyy-MM-dd HH:mm:ss', () {
    final text = insertTimestampText(
      localeName: 'en_US',
    );
    expect(text, matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
  });
}
