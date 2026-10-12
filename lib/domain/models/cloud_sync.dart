/// Aliyun Drive (or future provider) session used for cloud sync.
class CloudSyncSession {
  const CloudSyncSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.driveId,
    this.displayName = '',
    this.avatarUrl = '',
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String driveId;
  final String displayName;
  final String avatarUrl;

  bool get isAccessTokenFresh =>
      DateTime.now().isBefore(expiresAt.subtract(const Duration(minutes: 2)));

  CloudSyncSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? driveId,
    String? displayName,
    String? avatarUrl,
  }) => CloudSyncSession(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    driveId: driveId ?? this.driveId,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt.millisecondsSinceEpoch,
    'driveId': driveId,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
  };

  static CloudSyncSession? fromJson(Map<String, dynamic>? map) {
    if (map == null) return null;
    final access = map['accessToken'] as String?;
    final refresh = map['refreshToken'] as String?;
    final expires = map['expiresAt'];
    final driveId = map['driveId'] as String?;
    if (access == null ||
        refresh == null ||
        driveId == null ||
        expires is! int) {
      return null;
    }
    return CloudSyncSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expires),
      driveId: driveId,
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }
}

/// Non-secret preferences for cloud sync (app-support JSON).
class CloudSyncPreferences {
  const CloudSyncPreferences({
    this.autoSyncEnabled = true,
    this.lastSyncAt,
    this.lastSyncLibraryId,
    this.lastRemoteUpdatedAt,
  });

  final bool autoSyncEnabled;
  final DateTime? lastSyncAt;
  final String? lastSyncLibraryId;
  final DateTime? lastRemoteUpdatedAt;

  static const defaults = CloudSyncPreferences();

  CloudSyncPreferences copyWith({
    bool? autoSyncEnabled,
    DateTime? lastSyncAt,
    String? lastSyncLibraryId,
    DateTime? lastRemoteUpdatedAt,
    bool clearLastSyncAt = false,
    bool clearLastRemoteUpdatedAt = false,
  }) => CloudSyncPreferences(
    autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    lastSyncAt: clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
    lastSyncLibraryId: lastSyncLibraryId ?? this.lastSyncLibraryId,
    lastRemoteUpdatedAt: clearLastRemoteUpdatedAt
        ? null
        : (lastRemoteUpdatedAt ?? this.lastRemoteUpdatedAt),
  );

  Map<String, Object?> toJson() => {
    'autoSyncEnabled': autoSyncEnabled,
    if (lastSyncAt != null) 'lastSyncAt': lastSyncAt!.millisecondsSinceEpoch,
    if (lastSyncLibraryId != null) 'lastSyncLibraryId': lastSyncLibraryId,
    if (lastRemoteUpdatedAt != null)
      'lastRemoteUpdatedAt': lastRemoteUpdatedAt!.millisecondsSinceEpoch,
  };

  static CloudSyncPreferences fromJson(Map<String, dynamic> map) {
    final last = map['lastSyncAt'];
    final remote = map['lastRemoteUpdatedAt'];
    return CloudSyncPreferences(
      autoSyncEnabled: map['autoSyncEnabled'] as bool? ?? true,
      lastSyncAt: last is int ? DateTime.fromMillisecondsSinceEpoch(last) : null,
      lastSyncLibraryId: map['lastSyncLibraryId'] as String?,
      lastRemoteUpdatedAt: remote is int
          ? DateTime.fromMillisecondsSinceEpoch(remote)
          : null,
    );
  }
}

/// Manifest stored next to `library.pwb` on the user's Aliyun Drive.
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

/// One `.pwb` file listed under the library's cloud Backups folder.
class CloudBackupEntry {
  const CloudBackupEntry({
    required this.fileId,
    required this.fileName,
    required this.modified,
    required this.sizeBytes,
  });

  final String fileId;
  final String fileName;
  final DateTime modified;
  final int sizeBytes;
}

/// Open-platform AppId/Secret used by the Aliyun Drive client.
class AliyunDriveAppCredentials {
  const AliyunDriveAppCredentials({
    required this.clientId,
    required this.clientSecret,
  });

  final String clientId;
  final String clientSecret;

  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;
}

/// QR login challenge returned by Aliyun Drive OpenAPI.
class AliyunDriveQrChallenge {
  const AliyunDriveQrChallenge({required this.sid, required this.qrCodeUrl});

  final String sid;
  final String qrCodeUrl;
}

enum AliyunDriveQrStatus { waiting, scanned, success, expired, failed }

class AliyunDriveQrPollResult {
  const AliyunDriveQrPollResult({required this.status, this.authCode});

  final AliyunDriveQrStatus status;
  final String? authCode;
}
