import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zephyr/data/services/aliyun_drive_client.dart';
import 'package:zephyr/data/services/aliyun_drive_config.dart';
import 'package:zephyr/data/services/cloud_auth_secure_store.dart';
import 'package:zephyr/data/services/cloud_sync_preferences_storage.dart';
import 'package:zephyr/data/services/cloud_sync_service.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';

void main() {
  late _MemoryAuthStore auth;
  late _MemoryCloudPreferences preferences;

  setUp(() {
    auth = _MemoryAuthStore();
    preferences = _MemoryCloudPreferences();
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Zephyr',
      packageName: 'zephyr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test(
    'load combines stored credentials with configured fallback and session',
    () async {
      auth.credentials = const AliyunDriveAppCredentials(
        clientId: 'stored-id',
        clientSecret: 'stored-secret',
      );
      auth.session = _session(expiresIn: const Duration(hours: 1));
      final service = CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
        config: const AliyunDriveConfig(
          dartDefineClientId: 'fallback-id',
          dartDefineClientSecret: 'fallback-secret',
        ),
      );

      await service.load();

      expect(service.isAppConfigured, isTrue);
      expect(service.isSignedIn, isTrue);
      expect(service.session?.accessToken, 'access');
    },
  );

  test('expired session refreshes and saves new tokens on load', () async {
    auth.session = _session(expiresIn: const Duration(minutes: -1));
    final refreshed = _session(expiresIn: const Duration(hours: 1))
        .copyWith(accessToken: 'fresh');
    final client = _RefreshingClient(refreshed);
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
      clientFactory: (_) => client,
    );

    await service.load();

    expect(client.refreshToken, 'refresh');
    expect(client.closed, isTrue);
    expect(service.session?.accessToken, 'fresh');
    expect(auth.session?.accessToken, 'fresh');
  });

  test('failed token refresh signs out the stale session', () async {
    auth.session = _session(expiresIn: const Duration(minutes: -1));
    final client = _RefreshingClient(null);
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
      clientFactory: (_) => client,
    );

    await service.load();

    expect(service.isSignedIn, isFalse);
    expect(auth.session, isNull);
    expect(client.closed, isTrue);
  });

  test(
    'auto sync preference and credentials save through their stores',
    () async {
      final service = CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
      );
      await service.load();

      await service.setAutoSyncEnabled(false);
      await service.saveAppCredentials(
        const AliyunDriveAppCredentials(clientId: 'id', clientSecret: 'secret'),
      );

      expect(service.preferences.autoSyncEnabled, isFalse);
      expect(preferences.value.autoSyncEnabled, isFalse);
      expect(service.isAppConfigured, isTrue);
      expect(auth.credentials?.clientId, 'id');
    },
  );

  test('manual cloud backup flushes edits and uploads both copies', () async {
    auth.session = _session(expiresIn: const Duration(hours: 1));
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-cloud-workflow-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final client = _WorkflowClient();
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
      clientFactory: (_) => client,
    );
    await service.load();
    var flushes = 0;

    final uploaded = await service.backupNow(
      library: library,
      flushPending: () async => flushes++,
    );

    expect(flushes, 1);
    expect(library.createdKind, BackupKind.manual);
    expect(uploaded.fileName, 'backup.pwb');
    expect(client.namedUploads, 1);
    expect(client.snapshotUploads, 1);
    expect(client.closed, isTrue);
    expect(preferences.value.lastSyncLibraryId, 'library-id');
  });

  test(
    'sync merges a newer remote snapshot before uploading local data',
    () async {
      auth.session = _session(expiresIn: const Duration(hours: 1));
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-sync-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final library = _CloudLibraryRepository(directory);
      final client = _WorkflowClient()
        ..remoteManifest = CloudSyncManifest(
          libraryId: 'library-id',
          updatedAt: DateTime.now().add(const Duration(minutes: 1)),
          deviceName: 'other',
          appVersion: '0.1.0',
        );
      final service = CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
        clientFactory: (_) => client,
      );
      await service.load();

      await service.syncNow(library: library, flushPending: () async {});

      expect(library.restoredMode, RestoreMode.merge);
      expect(library.restoredFileExisted, isTrue);
      expect(library.createdKind, BackupKind.automatic);
      expect(client.snapshotUploads, 1);
      expect(client.namedUploads, 1);
      expect(client.closed, isTrue);
    },
  );

  test(
    'cloud restore cleans its staging file after applying the backup',
    () async {
      auth.session = _session(expiresIn: const Duration(hours: 1));
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-restore-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final library = _CloudLibraryRepository(directory);
      final client = _WorkflowClient();
      final service = CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
        clientFactory: (_) => client,
      );
      await service.load();
      final entry = CloudBackupEntry(
        fileId: 'remote',
        fileName: 'remote.pwb',
        modified: DateTime.utc(2026, 1, 1),
        sizeBytes: 3,
      );

      await service.restoreCloudBackup(
        library: library,
        entry: entry,
        mode: RestoreMode.overwrite,
        flushPending: () async {},
      );

      expect(library.restoredMode, RestoreMode.overwrite);
      expect(library.restoredFileExisted, isTrue);
      expect(await File(library.restoredPath!).exists(), isFalse);
      expect(client.closed, isTrue);
    },
  );
}

CloudSyncSession _session({required Duration expiresIn}) => CloudSyncSession(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(expiresIn),
  driveId: 'drive',
);

class _MemoryAuthStore extends CloudAuthSecureStore {
  CloudSyncSession? session;
  AliyunDriveAppCredentials? credentials;

  @override
  Future<CloudSyncSession?> loadSession() async => session;

  @override
  Future<void> saveSession(CloudSyncSession value) async {
    session = value;
  }

  @override
  Future<void> clearSession() async {
    session = null;
  }

  @override
  Future<AliyunDriveAppCredentials?> loadStoredAppCredentials() async =>
      credentials;

  @override
  Future<void> saveStoredAppCredentials(AliyunDriveAppCredentials value) async {
    credentials = value;
  }
}

class _MemoryCloudPreferences extends CloudSyncPreferencesStorage {
  CloudSyncPreferences value = CloudSyncPreferences.defaults;

  @override
  Future<CloudSyncPreferences> load() async => value;

  @override
  Future<void> save(CloudSyncPreferences preferences) async {
    value = preferences;
  }
}

class _RefreshingClient extends AliyunDriveClient {
  _RefreshingClient(this.result)
    : super(
        credentials: const AliyunDriveAppCredentials(
          clientId: 'id',
          clientSecret: 'secret',
        ),
      );

  final CloudSyncSession? result;
  String? refreshToken;
  bool closed = false;

  @override
  Future<CloudSyncSession> refresh(String refreshToken) async {
    this.refreshToken = refreshToken;
    if (result case final session?) return session;
    throw StateError('refresh failed');
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}

class _CloudLibraryRepository implements WritingLibraryRepository {
  _CloudLibraryRepository(this.directory);

  final Directory directory;
  BackupKind? createdKind;
  RestoreMode? restoredMode;
  String? restoredPath;
  bool restoredFileExisted = false;

  @override
  Future<String> ensureCloudLibraryId() async => 'library-id';

  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async {
    createdKind = kind;
    final file = File('${directory.path}/backup.pwb');
    await file.writeAsString('pwb');
    return BackupEntry(
      path: file.path,
      fileName: 'backup.pwb',
      modified: DateTime.utc(2026, 1, 1),
      sizeBytes: 3,
      kind: kind,
    );
  }

  @override
  Future<void> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async {
    restoredMode = mode;
    restoredPath = entry.path;
    restoredFileExisted = await File(entry.path).exists();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WorkflowClient extends AliyunDriveClient {
  _WorkflowClient()
    : super(
        credentials: const AliyunDriveAppCredentials(
          clientId: 'id',
          clientSecret: 'secret',
        ),
      );

  int namedUploads = 0;
  int snapshotUploads = 0;
  bool closed = false;
  CloudSyncManifest? remoteManifest;

  @override
  Future<String> ensureLibraryFolder({
    required CloudSyncSession session,
    required String libraryId,
  }) async => 'folder';

  @override
  Future<void> uploadNamedBackup({
    required CloudSyncSession session,
    required String libraryFolderId,
    required File pwb,
    required String fileName,
  }) async {
    expect(await pwb.exists(), isTrue);
    namedUploads++;
  }

  @override
  Future<void> uploadLibrarySnapshot({
    required CloudSyncSession session,
    required String parentFileId,
    required File pwb,
    required CloudSyncManifest manifest,
  }) async {
    expect(await pwb.exists(), isTrue);
    snapshotUploads++;
  }

  @override
  Future<CloudSyncManifest?> downloadManifest({
    required CloudSyncSession session,
    required String parentFileId,
  }) async => remoteManifest;

  @override
  Future<File?> downloadLibraryPwb({
    required CloudSyncSession session,
    required String parentFileId,
    required Directory staging,
  }) async {
    final file = File('${staging.path}/library.pwb');
    await file.writeAsString('remote');
    return file;
  }

  @override
  Future<File> downloadBackupFile({
    required CloudSyncSession session,
    required CloudBackupEntry entry,
    required Directory staging,
  }) async {
    final file = File('${staging.path}/${entry.fileName}');
    await file.writeAsString('remote');
    return file;
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}
