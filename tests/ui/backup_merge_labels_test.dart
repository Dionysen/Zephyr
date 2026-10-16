import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/l10n/app_localizations_en.dart';
import 'package:zephyr/l10n/app_localizations_zh.dart';
import 'package:zephyr/ui/features/settings/models/backup_merge_labels.dart';

void main() {
  test('merge result lists added, updated, and removed counts', () {
    const stats = LibraryMergeStats(
      articlesAdded: 2,
      articlesUpdated: 1,
      articlesRemoved: 3,
    );
    final en = backupMergeResultMessage(AppLocalizationsEn(), stats);
    expect(en, contains('Added 2'));
    expect(en, contains('Updated 1'));
    expect(en, contains('Deleted 3'));

    final zh = backupMergeResultMessage(AppLocalizationsZh(), stats);
    expect(zh, contains('新增 2 篇'));
    expect(zh, contains('更新 1 篇'));
    expect(zh, contains('删除 3 篇'));
  });

  test('merge result reports no changes when stats are empty', () {
    final message = backupMergeResultMessage(
      AppLocalizationsEn(),
      LibraryMergeStats.empty,
    );
    expect(message, 'Merge complete. No chapter changes.');
  });
}
