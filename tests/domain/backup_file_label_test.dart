import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/library_backup.dart';

void main() {
  test('toFileName embeds counts, version, and sanitized device', () {
    final label = BackupFileLabel(
      bookCount: 3,
      articleCount: 12,
      appVersion: '0.1.0',
      deviceName: 'Pixel 8 Pro',
      createdAt: DateTime(2026, 4, 10, 16, 45, 30),
    );
    expect(
      label.toFileName(),
      'Zephyr-2026-04-10-164530-Pixel-8-Pro-0.1.0-3books-12articles.pwb',
    );
  });

  test('sanitizeFileToken strips path separators and collapses dashes', () {
    expect(
      BackupFileLabel.sanitizeFileToken(r'C:\Foo/Bar:Baz', fallback: 'x'),
      'C-Foo-Bar-Baz',
    );
    expect(
      BackupFileLabel.sanitizeFileToken('   ', fallback: 'device'),
      'device',
    );
  });
}
