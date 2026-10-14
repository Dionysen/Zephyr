/// Kind of PureWriter-compatible `.pwb` under `{library}/Backups/`.
enum BackupKind { manual, automatic }

/// How to apply a selected `.pwb` onto the open library.
enum RestoreMode { overwrite, merge }

/// Chapter-level outcome of a merge restore (Article table).
class LibraryMergeStats {
  const LibraryMergeStats({
    this.articlesAdded = 0,
    this.articlesUpdated = 0,
    this.articlesRemoved = 0,
  });

  static const empty = LibraryMergeStats();

  final int articlesAdded;
  final int articlesUpdated;

  /// Remote rows applied that mark an article deleted (or newly deleted).
  final int articlesRemoved;

  bool get hasArticleChanges =>
      articlesAdded > 0 || articlesUpdated > 0 || articlesRemoved > 0;

  LibraryMergeStats operator +(LibraryMergeStats other) => LibraryMergeStats(
    articlesAdded: articlesAdded + other.articlesAdded,
    articlesUpdated: articlesUpdated + other.articlesUpdated,
    articlesRemoved: articlesRemoved + other.articlesRemoved,
  );
}

/// One `.pwb` file discovered under `Backups/` (including `Auto/`).
class BackupEntry {
  const BackupEntry({
    required this.path,
    required this.fileName,
    required this.modified,
    required this.sizeBytes,
    required this.kind,
  });

  final String path;
  final String fileName;
  final DateTime modified;
  final int sizeBytes;
  final BackupKind kind;
}

/// Crash-recovery draft stored in the Zephyr-only `ZephyrDraft` table.
class ArticleDraft {
  const ArticleDraft({
    required this.articleId,
    required this.content,
    required this.title,
    required this.updatedAt,
  });

  final String articleId;
  final String content;
  final String title;
  final DateTime updatedAt;
}

/// Metadata embedded in Zephyr `.pwb` filenames.
class BackupFileLabel {
  const BackupFileLabel({
    required this.bookCount,
    required this.articleCount,
    required this.appVersion,
    required this.deviceName,
    required this.createdAt,
  });

  final int bookCount;
  final int articleCount;
  final String appVersion;
  final String deviceName;
  final DateTime createdAt;

  /// e.g. `Zephyr-2026-04-10-164530123456-Pixel-8-0.1.0-3books-12articles.pwb`
  String toFileName() {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${createdAt.year}-${two(createdAt.month)}-${two(createdAt.day)}-'
        '${two(createdAt.hour)}${two(createdAt.minute)}${two(createdAt.second)}'
        '${createdAt.millisecond.toString().padLeft(3, '0')}'
        '${createdAt.microsecond.toString().padLeft(3, '0')}';
    final device = sanitizeFileToken(deviceName, fallback: 'device');
    final version = sanitizeFileToken(appVersion, fallback: '0');
    return 'Zephyr-$stamp-$device-$version-'
        '${bookCount}books-${articleCount}articles.pwb';
  }

  static String sanitizeFileToken(String input, {required String fallback}) {
    final cleaned = input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]+'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return cleaned.isEmpty ? fallback : cleaned;
  }
}

/// Preferences for local automatic `.pwb` backups (app-support JSON).
class BackupPreferences {
  const BackupPreferences({
    this.autoBackupEnabled = true,
    this.lastAutoBackupAt,
  });

  final bool autoBackupEnabled;
  final DateTime? lastAutoBackupAt;

  static const defaults = BackupPreferences();

  BackupPreferences copyWith({
    bool? autoBackupEnabled,
    DateTime? lastAutoBackupAt,
    bool clearLastAutoBackupAt = false,
  }) => BackupPreferences(
    autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    lastAutoBackupAt: clearLastAutoBackupAt
        ? null
        : (lastAutoBackupAt ?? this.lastAutoBackupAt),
  );
}
