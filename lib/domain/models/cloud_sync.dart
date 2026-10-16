import 'library_backup.dart';

enum CloudLibraryConflictReason { anotherLibrary, missingManifest }

/// A remote Zephyr folder cannot safely accept the current local library.
class CloudLibraryConflictException implements Exception {
  const CloudLibraryConflictException(this.reason);

  final CloudLibraryConflictReason reason;
}

/// WebDAV credentials kept in secure storage on this device.
class CloudSyncSession {
  const CloudSyncSession({
    required this.serverUrl,
    required this.username,
    required this.appPassword,
  });

  final String serverUrl;
  final String username;
  final String appPassword;

  Map<String, Object?> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'appPassword': appPassword,
  };

  static CloudSyncSession? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    final url = map['serverUrl'] as String?;
    final username = map['username'] as String?;
    final password = map['appPassword'] as String?;
    if (url == null ||
        username == null ||
        password == null ||
        url.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      return null;
    }
    return CloudSyncSession(
      serverUrl: url,
      username: username,
      appPassword: password,
    );
  }
}

/// Non-secret preferences for cloud sync (app-support JSON).
class CloudSyncPreferences {
  const CloudSyncPreferences({
    this.cloudBackupEnabled = true,
    this.pendingCloudBackup = false,
    this.lastSyncAt,
    this.lastSyncLibraryId,
    this.lastRemoteUpdatedAt,
  });

  /// Master switch for cloud backup UI and exit upload.
  final bool cloudBackupEnabled;

  /// Durable “local changes not yet on Nutstore” flag (survives process death).
  ///
  /// Set when content is persisted while cloud backup is on; cleared only after
  /// a successful [CloudSyncService.uploadLocalBackup]. Next launch catch-up
  /// reads this when in-memory dirty state is gone.
  final bool pendingCloudBackup;

  final DateTime? lastSyncAt;
  final String? lastSyncLibraryId;
  final DateTime? lastRemoteUpdatedAt;

  static const defaults = CloudSyncPreferences();

  CloudSyncPreferences copyWith({
    bool? cloudBackupEnabled,
    bool? pendingCloudBackup,
    DateTime? lastSyncAt,
    String? lastSyncLibraryId,
    DateTime? lastRemoteUpdatedAt,
    bool clearLastSyncAt = false,
    bool clearLastRemoteUpdatedAt = false,
  }) => CloudSyncPreferences(
    cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
    pendingCloudBackup: pendingCloudBackup ?? this.pendingCloudBackup,
    lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
    lastSyncLibraryId: lastSyncLibraryId ?? this.lastSyncLibraryId,
    lastRemoteUpdatedAt: clearLastRemoteUpdatedAt
        ? null
        : (lastRemoteUpdatedAt ?? this.lastRemoteUpdatedAt),
  );

  Map<String, Object?> toJson() => {
    'cloudBackupEnabled': cloudBackupEnabled,
    'pendingCloudBackup': pendingCloudBackup,
    if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.millisecondsSinceEpoch,
    if (lastSyncLibraryId != null) 'lastSyncLibraryId': lastSyncLibraryId,
    if (lastRemoteUpdatedAt != null)
      'lastRemoteUpdatedAt': lastRemoteUpdatedAt!.millisecondsSinceEpoch,
  };

  static CloudSyncPreferences fromJson(Map<String, dynamic> map) {
    final last = map['lastSyncAt'];
    final remote = map['lastRemoteUpdatedAt'];
    return CloudSyncPreferences(
      cloudBackupEnabled: map['cloudBackupEnabled'] as bool? ?? true,
      pendingCloudBackup: map['pendingCloudBackup'] as bool? ?? false,
      lastSyncAt: last is int
          ? DateTime.fromMillisecondsSinceEpoch(last)
          : null,
      lastSyncLibraryId: map['lastSyncLibraryId'] as String?,
      lastRemoteUpdatedAt: remote is int
          ? DateTime.fromMillisecondsSinceEpoch(remote)
          : null,
    );
  }
}

/// Manifest stored next to `library.pwb` on WebDAV.
class CloudSyncManifest {
  const CloudSyncManifest({
    required this.libraryId,
    required this.updatedAt,
    required this.deviceName,
    required this.appVersion,
    this.schema = 1,
  });

  final String libraryId;
  final DateTime updatedAt;
  final String deviceName;
  final String appVersion;
  final int schema;

  Map<String, Object?> toJson() => {
    'schema': schema,
    'libraryId': libraryId,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'deviceName': deviceName,
    'appVersion': appVersion,
  };

  static CloudSyncManifest? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    final libraryId = map['libraryId'] as String?;
    final updatedAt = map['updatedAt'];
    if (libraryId == null || updatedAt is! int) return null;
    return CloudSyncManifest(
      libraryId: libraryId,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      deviceName: map['deviceName'] as String? ?? '',
      appVersion: map['appVersion'] as String? ?? '',
      schema: map['schema'] as int? ?? 1,
    );
  }
}

/// One restorable `.pwb` on WebDAV — either the latest snapshot or a history
/// file under `Zephyr/Backups/`.
class CloudBackupEntry {
  const CloudBackupEntry({
    required this.fileId,
    required this.fileName,
    required this.modified,
    required this.sizeBytes,
    this.isLatestSnapshot = false,
  });

  final String fileId;
  final String fileName;
  final DateTime modified;
  final int sizeBytes;

  /// [fileName] is `library.pwb` under the Zephyr folder (not `Backups/`).
  final bool isLatestSnapshot;
}

/// Result of [CloudSyncService.pullIfNewer].
class CloudPullResult {
  const CloudPullResult({
    this.pulled = false,
    this.mergeStats = LibraryMergeStats.empty,
  });

  static const skipped = CloudPullResult();

  final bool pulled;
  final LibraryMergeStats mergeStats;
}
