/// Kind of PureWriter-compatible `.pwb` under `{library}/Backups/`.
enum BackupKind { manual, automatic }

/// How to apply a selected `.pwb` onto the open library.
enum RestoreMode { overwrite, merge }

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
