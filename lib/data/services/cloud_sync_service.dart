import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/cloud_sync.dart';
import '../../domain/models/library_backup.dart';
import '../../domain/repositories/writing_library_repository.dart';
import 'cloud_auth_secure_store.dart';
import 'cloud_settings_bundle.dart';
import 'cloud_sync_preferences_storage.dart';
import 'device_label.dart';
import 'webdav_client.dart';

/// Orchestrates WebDAV credentials, cloud backups, and snapshot sync.
class CloudSyncService {
  static const cloudBackupKeepCount = 25;
  CloudSyncService({
    CloudAuthSecureStore? authStore,
    CloudSyncPreferencesStorage? preferencesStorage,
    CloudSettingsBundle? settingsBundle,
    WebDavClient Function()? clientFactory,
  }) : _authStore = authStore ?? CloudAuthSecureStore(),
       _preferencesStorage =
           preferencesStorage ?? CloudSyncPreferencesStorage(),
       _settingsBundle = settingsBundle ?? CloudSettingsBundle(),
       _clientFactory = clientFactory ?? WebDavClient.new;

  final CloudAuthSecureStore _authStore;
  final CloudSyncPreferencesStorage _preferencesStorage;
  final CloudSettingsBundle _settingsBundle;
  final WebDavClient Function() _clientFactory;

  CloudSyncSession? _session;
  CloudSyncPreferences _preferences = CloudSyncPreferences.defaults;

  CloudSyncSession? get session => _session;
  CloudSyncPreferences get preferences => _preferences;
  bool get isSignedIn => _session != null;
  bool get cloudBackupEnabled => _preferences.cloudBackupEnabled;

  Future<void> load() async {
    _preferences = await _preferencesStorage.load();
    _session = await _authStore.loadSession();
  }

  Future<void> connect(CloudSyncSession session) async {
    await _withClient((client) => client.verifyConnection(session));
    if (_session?.serverUrl != session.serverUrl ||
        _session?.username != session.username) {
      _preferences = _preferences.copyWith(
        clearLastSyncAt: true,
        clearLastRemoteUpdatedAt: true,
      );
      await _preferencesStorage.save(_preferences);
    }
    _session = session;
    await _authStore.saveSession(session);
  }

  Future<void> signOut() async {
    _session = null;
    await _authStore.clearSession();
  }

  Future<void> setCloudBackupEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(cloudBackupEnabled: enabled);
    await _preferencesStorage.save(_preferences);
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(autoSyncEnabled: enabled);
    await _preferencesStorage.save(_preferences);
  }

  /// Create a local `.pwb` then upload that same file to Nutstore.
  Future<CloudBackupEntry> backupNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
    BackupKind kind = BackupKind.manual,
  }) async {
    _requireCloudBackup();
    final session = _requireSession();
    await flushPending();
    final entry = await library.createBackup(kind: kind);
    return uploadLocalBackup(library: library, entry: entry, session: session);
  }

  /// Upload an existing local backup as the latest snapshot + history copy.
  Future<CloudBackupEntry> uploadLocalBackup({
    required WritingLibraryRepository library,
    required BackupEntry entry,
    CloudSyncSession? session,
  }) async {
    _requireCloudBackup();
    final active = session ?? _requireSession();
    final client = _clientFactory();
    try {
      final folderId = await client.ensureLibraryFolder(session: active);
      // Never claim an empty library on upload — that would publish a new id
      // over someone else's cloud folder.
      final remote = await _resolveRemoteLibrary(
        client: client,
        session: active,
        folderId: folderId,
        library: library,
        allowClaimEmpty: false,
      );
      // After an empty-library claim for restore/list, refuse publishing an
      // empty Room.db over an existing cloud snapshot.
      if (remote != null && !await library.hasArticleContent()) {
        throw StateError(
          'Refusing to upload an empty library over an existing cloud backup.',
        );
      }
      final libraryId = await library.ensureCloudLibraryId();
      final package = await PackageInfo.fromPlatform();
      final device = await resolveDeviceLabel();
      final manifest = CloudSyncManifest(
        libraryId: libraryId,
        updatedAt: DateTime.now(),
        deviceName: device,
        appVersion: package.version,
      );
      await client.uploadLibrarySnapshot(
        session: active,
        parentFileId: folderId,
        pwb: File(entry.path),
        manifest: manifest,
      );
      await client.uploadNamedBackup(
        session: active,
        libraryFolderId: folderId,
        pwb: File(entry.path),
        fileName: entry.fileName,
      );
      await client.uploadSettingsBundle(
        session: active,
        parentFileId: folderId,
        fileName: _settingsBundle.cloudFileName,
        bytes: await _settingsBundle.exportBytes(),
      );
      _preferences = _preferences.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncLibraryId: libraryId,
        lastRemoteUpdatedAt: manifest.updatedAt,
      );
      await _preferencesStorage.save(_preferences);
      await _pruneCloudBackups(client, active, folderId);
      return CloudBackupEntry(
        fileId: '',
        fileName: entry.fileName,
        modified: entry.modified,
        sizeBytes: entry.sizeBytes,
      );
    } finally {
      client.close();
    }
  }

  Future<List<CloudBackupEntry>> listCloudBackups({
    required WritingLibraryRepository library,
  }) async {
    _requireCloudBackup();
    final session = _requireSession();
    return _withClient((client) async {
      final folderId = await client.ensureLibraryFolder(session: session);
      await _resolveRemoteLibrary(
        client: client,
        session: session,
        folderId: folderId,
        library: library,
        allowClaimEmpty: true,
      );
      return client.listNamedBackups(
        session: session,
        libraryFolderId: folderId,
      );
    });
  }

  Future<void> restoreCloudBackup({
    required WritingLibraryRepository library,
    required CloudBackupEntry entry,
    required RestoreMode mode,
    required Future<void> Function() flushPending,
  }) async {
    _requireCloudBackup();
    final session = _requireSession();
    await flushPending();
    final staging = await Directory.systemTemp.createTemp(
      'zephyr-cloud-restore-',
    );
    final client = _clientFactory();
    try {
      final folderId = await client.ensureLibraryFolder(session: session);
      await _resolveRemoteLibrary(
        client: client,
        session: session,
        folderId: folderId,
        library: library,
        allowClaimEmpty: true,
      );
      final pwb = await client.downloadBackupFile(
        session: session,
        entry: entry,
        staging: staging,
      );
      await library.restoreBackup(
        entry: BackupEntry(
          path: pwb.path,
          fileName: entry.fileName,
          modified: entry.modified,
          sizeBytes: entry.sizeBytes,
          kind: BackupKind.manual,
        ),
        mode: mode,
      );
      await _downloadAndApplySettings(client, session, folderId);
    } finally {
      client.close();
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  /// Pull remote latest snapshot when newer and merge; never upload.
  Future<CloudPullResult> pullIfNewer({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    _requireCloudBackup();
    final session = _requireSession();
    await flushPending();
    final client = _clientFactory();
    try {
      final folderId = await client.ensureLibraryFolder(session: session);
      final remoteManifest = await _resolveRemoteLibrary(
        client: client,
        session: session,
        folderId: folderId,
        library: library,
        allowClaimEmpty: true,
      );
      if (remoteManifest == null) return CloudPullResult.skipped;
      final libraryId = await library.ensureCloudLibraryId();
      final shouldPull =
          _preferences.lastSyncLibraryId != libraryId ||
          _preferences.lastRemoteUpdatedAt == null ||
          remoteManifest.updatedAt.isAfter(_preferences.lastRemoteUpdatedAt!);
      if (!shouldPull) {
        // Still refresh settings when the library snapshot is unchanged.
        await _downloadAndApplySettings(client, session, folderId);
        return CloudPullResult.skipped;
      }

      late final LibraryMergeStats mergeStats;
      final staging = await Directory.systemTemp.createTemp(
        'zephyr-cloud-pull-',
      );
      try {
        final pwb = await client.downloadLibraryPwb(
          session: session,
          parentFileId: folderId,
          staging: staging,
        );
        if (pwb == null) {
          throw StateError('Cloud manifest exists without library.pwb.');
        }
        // Empty local libraries prefer overwrite so ZephyrMeta (incl. cloud id)
        // matches the snapshot; otherwise merge by chapter updateTime.
        final mode = await library.hasArticleContent()
            ? RestoreMode.merge
            : RestoreMode.overwrite;
        mergeStats = await library.restoreBackup(
          entry: BackupEntry(
            path: pwb.path,
            fileName: path.basename(pwb.path),
            modified: remoteManifest.updatedAt,
            sizeBytes: await pwb.length(),
            kind: BackupKind.manual,
          ),
          mode: mode,
        );
      } finally {
        if (await staging.exists()) {
          await staging.delete(recursive: true);
        }
      }

      await _downloadAndApplySettings(client, session, folderId);
      _preferences = _preferences.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncLibraryId: libraryId,
        lastRemoteUpdatedAt: remoteManifest.updatedAt,
      );
      await _preferencesStorage.save(_preferences);
      return CloudPullResult(pulled: true, mergeStats: mergeStats);
    } finally {
      client.close();
    }
  }

  /// Pull-merge then push (manual full sync). Prefer [pullIfNewer] + exit upload.
  Future<CloudSyncManifest> syncNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    await pullIfNewer(library: library, flushPending: flushPending);
    final entry = await library.createBackup(kind: BackupKind.automatic);
    await uploadLocalBackup(library: library, entry: entry);
    return CloudSyncManifest(
      libraryId: _preferences.lastSyncLibraryId ?? '',
      updatedAt: _preferences.lastRemoteUpdatedAt ?? DateTime.now(),
      deviceName: '',
      appVersion: '',
    );
  }

  void _requireCloudBackup() {
    if (!_preferences.cloudBackupEnabled) {
      throw StateError('Cloud backup is disabled.');
    }
  }

  CloudSyncSession _requireSession() {
    final session = _session;
    if (session == null) {
      throw StateError('WebDAV account is not connected.');
    }
    return session;
  }

  Future<void> _pruneCloudBackups(
    WebDavClient client,
    CloudSyncSession session,
    String folderId,
  ) async {
    final backups = await client.listNamedBackups(
      session: session,
      libraryFolderId: folderId,
    );
    final owned = backups
        .where((entry) => entry.fileName.startsWith('Zephyr-'))
        .toList();
    for (final entry in owned.skip(cloudBackupKeepCount)) {
      await client.deleteNamedBackup(session: session, entry: entry);
    }
  }

  /// Validates remote folder ownership. Empty local libraries may claim the
  /// remote [CloudSyncManifest.libraryId] when [allowClaimEmpty] is true.
  Future<CloudSyncManifest?> _resolveRemoteLibrary({
    required WebDavClient client,
    required CloudSyncSession session,
    required String folderId,
    required WritingLibraryRepository library,
    required bool allowClaimEmpty,
  }) async {
    final libraryId = await library.ensureCloudLibraryId();
    final manifest = await client.downloadManifest(
      session: session,
      parentFileId: folderId,
    );
    if (manifest != null && manifest.libraryId != libraryId) {
      if (allowClaimEmpty && !await library.hasArticleContent()) {
        await library.setCloudLibraryId(manifest.libraryId);
      } else {
        throw const CloudLibraryConflictException(
          CloudLibraryConflictReason.anotherLibrary,
        );
      }
    }
    if (manifest == null &&
        await client.hasUntrackedContent(
          session: session,
          parentFileId: folderId,
        )) {
      throw const CloudLibraryConflictException(
        CloudLibraryConflictReason.missingManifest,
      );
    }
    return manifest;
  }

  Future<void> _downloadAndApplySettings(
    WebDavClient client,
    CloudSyncSession session,
    String folderId,
  ) async {
    final bytes = await client.downloadSettingsBundle(
      session: session,
      parentFileId: folderId,
      fileName: _settingsBundle.cloudFileName,
      fallbackFileName: _settingsBundle.legacyCloudFileNameFallback,
    );
    if (bytes == null || bytes.isEmpty) return;
    await _settingsBundle.importBytes(bytes);
  }

  Future<T> _withClient<T>(
    Future<T> Function(WebDavClient client) action,
  ) async {
    final client = _clientFactory();
    try {
      return await action(client);
    } finally {
      client.close();
    }
  }
}
