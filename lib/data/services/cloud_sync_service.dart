import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/cloud_sync.dart';
import '../../domain/models/library_backup.dart';
import '../../domain/repositories/writing_library_repository.dart';
import 'cloud_auth_secure_store.dart';
import 'cloud_sync_preferences_storage.dart';
import 'device_label.dart';
import 'webdav_client.dart';

/// Orchestrates WebDAV credentials, cloud backups, and snapshot sync.
class CloudSyncService {
  CloudSyncService({
    CloudAuthSecureStore? authStore,
    CloudSyncPreferencesStorage? preferencesStorage,
    WebDavClient Function()? clientFactory,
  }) : _authStore = authStore ?? CloudAuthSecureStore(),
       _preferencesStorage =
           preferencesStorage ?? CloudSyncPreferencesStorage(),
       _clientFactory = clientFactory ?? WebDavClient.new;

  final CloudAuthSecureStore _authStore;
  final CloudSyncPreferencesStorage _preferencesStorage;
  final WebDavClient Function() _clientFactory;

  CloudSyncSession? _session;
  CloudSyncPreferences _preferences = CloudSyncPreferences.defaults;

  CloudSyncSession? get session => _session;
  CloudSyncPreferences get preferences => _preferences;
  bool get isSignedIn => _session != null;

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

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _preferences = _preferences.copyWith(autoSyncEnabled: enabled);
    await _preferencesStorage.save(_preferences);
  }

  /// Manual cloud backup: local `.pwb` + upload into cloud `Backups/`, and
  /// refresh latest `library.pwb` for auto-sync peers.
  Future<CloudBackupEntry> backupNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    final session = _requireSession();
    await flushPending();
    final libraryId = await library.ensureCloudLibraryId();
    final entry = await library.createBackup(kind: BackupKind.manual);
    final client = _clientFactory();
    try {
      final folderId = await client.ensureLibraryFolder(
        session: session,
        libraryId: libraryId,
      );
      await client.uploadNamedBackup(
        session: session,
        libraryFolderId: folderId,
        pwb: File(entry.path),
        fileName: entry.fileName,
      );
      final package = await PackageInfo.fromPlatform();
      final device = await resolveDeviceLabel();
      final manifest = CloudSyncManifest(
        libraryId: libraryId,
        updatedAt: DateTime.now(),
        deviceName: device,
        appVersion: package.version,
      );
      await client.uploadLibrarySnapshot(
        session: session,
        parentFileId: folderId,
        pwb: File(entry.path),
        manifest: manifest,
      );
      _preferences = _preferences.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncLibraryId: libraryId,
        lastRemoteUpdatedAt: manifest.updatedAt,
      );
      await _preferencesStorage.save(_preferences);
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
    final session = _requireSession();
    final libraryId = await library.ensureCloudLibraryId();
    return _withClient((client) async {
      final folderId = await client.ensureLibraryFolder(
        session: session,
        libraryId: libraryId,
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
    final session = _requireSession();
    await flushPending();
    final staging = await Directory.systemTemp.createTemp(
      'zephyr-cloud-restore-',
    );
    final client = _clientFactory();
    try {
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
    } finally {
      client.close();
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  /// Pull remote latest (if newer) with merge, then push local snapshot.
  Future<CloudSyncManifest> syncNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    final session = _requireSession();
    await flushPending();
    final libraryId = await library.ensureCloudLibraryId();
    final client = _clientFactory();
    try {
      final folderId = await client.ensureLibraryFolder(
        session: session,
        libraryId: libraryId,
      );
      final remoteManifest = await client.downloadManifest(
        session: session,
        parentFileId: folderId,
      );
      if (remoteManifest != null && remoteManifest.libraryId != libraryId) {
        throw StateError('Cloud snapshot belongs to another library.');
      }
      final shouldPull =
          remoteManifest != null &&
          (_preferences.lastSyncLibraryId != libraryId ||
              _preferences.lastRemoteUpdatedAt == null ||
              remoteManifest.updatedAt.isAfter(
                _preferences.lastRemoteUpdatedAt!,
              ));
      if (shouldPull) {
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
          await library.restoreBackup(
            entry: BackupEntry(
              path: pwb.path,
              fileName: path.basename(pwb.path),
              modified: remoteManifest.updatedAt,
              sizeBytes: await pwb.length(),
              kind: BackupKind.manual,
            ),
            mode: RestoreMode.merge,
          );
        } finally {
          if (await staging.exists()) {
            await staging.delete(recursive: true);
          }
        }
      }

      final entry = await library.createBackup(kind: BackupKind.automatic);
      final package = await PackageInfo.fromPlatform();
      final device = await resolveDeviceLabel();
      final manifest = CloudSyncManifest(
        libraryId: libraryId,
        updatedAt: DateTime.now(),
        deviceName: device,
        appVersion: package.version,
      );
      await client.uploadLibrarySnapshot(
        session: session,
        parentFileId: folderId,
        pwb: File(entry.path),
        manifest: manifest,
      );
      // Also keep a dated copy for the restore list.
      await client.uploadNamedBackup(
        session: session,
        libraryFolderId: folderId,
        pwb: File(entry.path),
        fileName: entry.fileName,
      );
      _preferences = _preferences.copyWith(
        lastSyncAt: DateTime.now(),
        lastSyncLibraryId: libraryId,
        lastRemoteUpdatedAt: manifest.updatedAt,
      );
      await _preferencesStorage.save(_preferences);
      return manifest;
    } finally {
      client.close();
    }
  }

  CloudSyncSession _requireSession() {
    final session = _session;
    if (session == null) {
      throw StateError('WebDAV account is not connected.');
    }
    return session;
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
