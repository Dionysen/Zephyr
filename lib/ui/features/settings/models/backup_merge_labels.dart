import '../../../../domain/models/library_backup.dart';
import '../../../core/zephyr_l10n.dart';

/// User-visible summary after a merge restore (local or cloud).
String backupMergeResultMessage(
  AppLocalizations l10n,
  LibraryMergeStats stats,
) {
  if (!stats.hasArticleChanges) {
    return l10n.backupMergeResultNoChanges;
  }
  final parts = <String>[];
  if (stats.articlesAdded > 0) {
    parts.add(l10n.backupMergeResultAdded(stats.articlesAdded));
  }
  if (stats.articlesUpdated > 0) {
    parts.add(l10n.backupMergeResultUpdated(stats.articlesUpdated));
  }
  if (stats.articlesRemoved > 0) {
    parts.add(l10n.backupMergeResultRemoved(stats.articlesRemoved));
  }
  return '${l10n.backupMergeResultTitle}: ${parts.join(l10n.backupMergeResultSeparator)}';
}
