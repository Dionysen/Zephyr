import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zephyr/data/services/cloud_auth_secure_store.dart';
import 'package:zephyr/data/services/cloud_settings_bundle.dart';
import 'package:zephyr/data/services/cloud_sync_preferences_storage.dart';
import 'package:zephyr/data/services/cloud_sync_service.dart';
import 'package:zephyr/data/services/webdav_client.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';

void main() {
  late _MemoryAuthStore auth;
  late _MemoryCloudPreferences preferences;

  setUp(() {
    auth = _MemoryAuthStore();
    preferences = _MemoryCloudPreferences();
    preferences.value = const CloudSyncPreferences(cloudBackupEnabled: true);
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Zephyr',
      packageName: 'zephyr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  CloudSyncService serviceWith(WebDavClient Function() clientFactory) =>
      CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
        settingsBundle: _MemorySettingsBundle(),
        clientFactory: clientFactory,
      );

  test('load restores stored WebDAV credentials', () async {
    auth.session = _session();
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
    );
    await service.load();
    expect(service.isSignedIn, isTrue);
    expect(service.session?.username, 'writer@example.com');
  });

  test('connect verifies credentials before saving them', () async {
    final client = _WorkflowClient();
    final service = serviceWith(() => client);
    await service.connect(_session());
    expect(
      client.verifiedSession?.serverUrl,
      'https://dav.jianguoyun.com/dav/',
    );
    expect(auth.session?.username, 'writer@example.com');
    expect(client.closed, isTrue);
  });

  test('failed connection leaves existing credentials intact', () async {
    auth.session = _session();
    final client = _WorkflowClient()..failVerification = true;
    final service = serviceWith(() => client);
    await service.load();
    await expectLater(
      service.connect(
        const CloudSyncSession(
          serverUrl: 'https://invalid.example/dav/',
          username: 'other',
          appPassword: 'wrong',
        ),
      ),
      throwsStateError,
    );
    expect(service.session?.username, 'writer@example.com');
    expect(auth.session?.username, 'writer@example.com');
  });

  test(
    'connecting another account clears the previous remote cursor',
    () async {
      auth.session = _session();
      preferences.value = CloudSyncPreferences(
        lastSyncAt: DateTime.utc(2026, 9, 1),
        lastSyncLibraryId: 'library-id',
        lastRemoteUpdatedAt: DateTime.utc(2026, 9, 1),
      );
      final service = CloudSyncService(
        authStore: auth,
        preferencesStorage: preferences,
        clientFactory: _WorkflowClient.new,
      );
      await service.load();
      await service.connect(
        const CloudSyncSession(
          serverUrl: 'https://dav.jianguoyun.com/dav/',
          username: 'other@example.com',
          appPassword: 'other-password',
        ),
      );
      expect(service.preferences.lastSyncAt, isNull);
      expect(service.preferences.lastRemoteUpdatedAt, isNull);
      expect(auth.session?.username, 'other@example.com');
    },
  );

  test('auto sync preference saves through its store', () async {
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
    );
    await service.load();

    await service.setAutoSyncEnabled(false);

    expect(service.preferences.autoSyncEnabled, isFalse);
    expect(preferences.value.autoSyncEnabled, isFalse);
  });

  test('cloud backup preference saves through its store', () async {
    preferences.value = const CloudSyncPreferences(cloudBackupEnabled: true);
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
    );
    await service.load();
    expect(service.cloudBackupEnabled, isTrue);

    await service.setCloudBackupEnabled(false);

    expect(service.cloudBackupEnabled, isFalse);
    expect(preferences.value.cloudBackupEnabled, isFalse);

    await service.setCloudBackupEnabled(true);
    expect(preferences.value.cloudBackupEnabled, isTrue);
  });

  test(
    'pullIfNewer merges a newer remote snapshot without uploading',
    () async {
      auth.session = _session();
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-pull-',
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
      final service = serviceWith(() => client);
      await service.load();

      final pulled = await service.pullIfNewer(
        library: library,
        flushPending: () async {},
      );

      expect(pulled.pulled, isTrue);
      expect(pulled.mergeStats.articlesAdded, 1);
      expect(library.restoredMode, RestoreMode.merge);
      expect(library.createdKind, isNull);
      expect(client.snapshotUploads, 0);
      expect(client.namedUploads, 0);
      expect(client.closed, isTrue);
    },
  );

  test('pullIfNewer skips when remote is not newer', () async {
    auth.session = _session();
    final remoteAt = DateTime.utc(2026, 1, 1);
    preferences.value = CloudSyncPreferences(
      cloudBackupEnabled: true,
      lastSyncLibraryId: 'library-id',
      lastRemoteUpdatedAt: remoteAt,
    );
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-cloud-pull-skip-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final client = _WorkflowClient()
      ..remoteManifest = CloudSyncManifest(
        libraryId: 'library-id',
        updatedAt: remoteAt,
        deviceName: 'other',
        appVersion: '0.1.0',
      );
    final service = serviceWith(() => client);
    await service.load();

    final pulled = await service.pullIfNewer(
      library: library,
      flushPending: () async {},
    );

    expect(pulled.pulled, isFalse);
    expect(library.restoredMode, isNull);
    expect(client.snapshotUploads, 0);
  });

  test('uploadLocalBackup uploads an existing local file once', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-cloud-upload-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final entry = await library.createBackup(kind: BackupKind.automatic);
    final client = _WorkflowClient();
    final service = serviceWith(() => client);
    await service.load();

    await service.uploadLocalBackup(library: library, entry: entry);

    expect(library.createCalls, 1);
    expect(client.snapshotUploads, 1);
    expect(client.namedUploads, 1);
    expect(client.uploadOrder, ['snapshot', 'backup', 'settings']);
  });

  test('cloud operations fail when cloud backup is disabled', () async {
    preferences.value = const CloudSyncPreferences(cloudBackupEnabled: false);
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-cloud-disabled-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final service = CloudSyncService(
      authStore: auth,
      preferencesStorage: preferences,
      clientFactory: _WorkflowClient.new,
    );
    await service.load();

    await expectLater(
      service.backupNow(library: library, flushPending: () async {}),
      throwsStateError,
    );
    await expectLater(
      service.pullIfNewer(library: library, flushPending: () async {}),
      throwsStateError,
    );
  });

  test('manual cloud backup flushes edits and uploads both copies', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-cloud-workflow-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final client = _WorkflowClient();
    final service = serviceWith(() => client);
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
    expect(client.uploadOrder, ['snapshot', 'backup', 'settings']);
    expect(client.closed, isTrue);
    expect(preferences.value.lastSyncLibraryId, 'library-id');
  });

  test(
    'cloud backup deletes only Zephyr history older than 25 copies',
    () async {
      auth.session = _session();
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-prune-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final client = _WorkflowClient();
      client.backups.addAll([
        for (var day = 1; day <= 27; day++)
          CloudBackupEntry(
            fileId:
                'https://dav.jianguoyun.com/dav/Zephyr/Backups/Zephyr-$day.pwb',
            fileName: 'Zephyr-$day.pwb',
            modified: DateTime.utc(2026, 1, day),
            sizeBytes: day,
          ),
        CloudBackupEntry(
          fileId: 'foreign',
          fileName: 'PureWriter.pwb',
          modified: DateTime.utc(2025),
          sizeBytes: 1,
        ),
      ]);
      final service = serviceWith(() => client);
      await service.load();

      await service.syncNow(
        library: _CloudLibraryRepository(directory),
        flushPending: () async {},
      );

      expect(client.deleted.map((entry) => entry.fileName), [
        'Zephyr-2.pwb',
        'Zephyr-1.pwb',
      ]);
      expect(client.snapshotUploads, 1);
    },
  );

  test(
    'sync merges a newer remote snapshot before uploading local data',
    () async {
      auth.session = _session();
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
      final service = serviceWith(() => client);
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
    'sync rejects a snapshot from another library before uploading',
    () async {
      auth.session = _session();
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-mismatch-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final library = _CloudLibraryRepository(directory);
      final client = _WorkflowClient()
        ..remoteManifest = CloudSyncManifest(
          libraryId: 'another-library',
          updatedAt: DateTime.utc(2026, 9, 1),
          deviceName: 'other',
          appVersion: '0.1.0',
        );
      final service = serviceWith(() => client);
      await service.load();

      await expectLater(
        service.syncNow(library: library, flushPending: () async {}),
        throwsA(
          isA<CloudLibraryConflictException>().having(
            (error) => error.reason,
            'reason',
            CloudLibraryConflictReason.anotherLibrary,
          ),
        ),
      );
      expect(client.snapshotUploads, 0);
      expect(client.namedUploads, 0);
      expect(client.closed, isTrue);
    },
  );

  test('manual backup rejects another library before uploading', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp('zephyr-cloud-');
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final client = _WorkflowClient()
      ..remoteManifest = CloudSyncManifest(
        libraryId: 'another-library',
        updatedAt: DateTime.utc(2026, 9, 1),
        deviceName: 'other',
        appVersion: '0.1.0',
      );
    final service = serviceWith(() => client);
    await service.load();

    await expectLater(
      service.backupNow(library: library, flushPending: () async {}),
      throwsA(isA<CloudLibraryConflictException>()),
    );
    expect(client.snapshotUploads, 0);
    expect(client.namedUploads, 0);
    expect(client.closed, isTrue);
  });

  test('listing and restoring reject a different cloud library with content', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp('zephyr-cloud-');
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory)..hasArticles = true;
    final client = _WorkflowClient()
      ..remoteManifest = CloudSyncManifest(
        libraryId: 'another-library',
        updatedAt: DateTime.utc(2026, 9, 1),
        deviceName: 'other',
        appVersion: '0.1.0',
      );
    final service = serviceWith(() => client);
    await service.load();

    await expectLater(
      service.listCloudBackups(library: library),
      throwsA(isA<CloudLibraryConflictException>()),
    );
    await expectLater(
      service.restoreCloudBackup(
        library: library,
        entry: CloudBackupEntry(
          fileId: 'https://dav.jianguoyun.com/dav/Zephyr/Backups/one.pwb',
          fileName: 'one.pwb',
          modified: DateTime.utc(2026, 9, 1),
          sizeBytes: 3,
        ),
        mode: RestoreMode.overwrite,
        flushPending: () async {},
      ),
      throwsA(isA<CloudLibraryConflictException>()),
    );
    expect(library.restoredMode, isNull);
    expect(library.cloudLibraryId, 'library-id');
  });

  test('empty library claims remote id then lists and restores', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp('zephyr-cloud-');
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory)..hasArticles = false;
    final client = _WorkflowClient()
      ..remoteManifest = CloudSyncManifest(
        libraryId: 'another-library',
        updatedAt: DateTime.utc(2026, 9, 1),
        deviceName: 'other',
        appVersion: '0.1.0',
      );
    final service = serviceWith(() => client);
    await service.load();

    final listed = await service.listCloudBackups(library: library);
    expect(listed, isEmpty);
    expect(library.cloudLibraryId, 'another-library');

    await service.restoreCloudBackup(
      library: library,
      entry: CloudBackupEntry(
        fileId: 'https://dav.jianguoyun.com/dav/Zephyr/Backups/one.pwb',
        fileName: 'one.pwb',
        modified: DateTime.utc(2026, 9, 1),
        sizeBytes: 3,
      ),
      mode: RestoreMode.overwrite,
      flushPending: () async {},
    );
    expect(library.restoredMode, RestoreMode.overwrite);
    expect(client.settingsDownloads, 1);
  });

  test('upload refuses empty library over existing remote snapshot', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp('zephyr-cloud-');
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory)..hasArticles = false;
    final client = _WorkflowClient()
      ..remoteManifest = CloudSyncManifest(
        libraryId: 'claimed-library',
        updatedAt: DateTime.utc(2026, 9, 1),
        deviceName: 'other',
        appVersion: '0.1.0',
      );
    final service = serviceWith(() => client);
    await service.load();
    // Claim via list so local cloud id matches remote.
    await service.listCloudBackups(library: library);
    expect(library.cloudLibraryId, 'claimed-library');

    final pwb = File('${directory.path}/empty.pwb');
    await pwb.writeAsBytes([1, 2, 3]);
    await expectLater(
      service.uploadLocalBackup(
        library: library,
        entry: BackupEntry(
          path: pwb.path,
          fileName: 'empty.pwb',
          modified: DateTime.utc(2026, 9, 2),
          sizeBytes: 3,
          kind: BackupKind.manual,
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('empty library'),
        ),
      ),
    );
    expect(client.snapshotUploads, 0);
    expect(client.settingsUploads, 0);
  });

  test('sync refuses an untracked remote snapshot', () async {
    auth.session = _session();
    final directory = await Directory.systemTemp.createTemp('zephyr-cloud-');
    addTearDown(() => directory.delete(recursive: true));
    final library = _CloudLibraryRepository(directory);
    final client = _WorkflowClient()..untrackedContent = true;
    final service = serviceWith(() => client);
    await service.load();

    await expectLater(
      service.syncNow(library: library, flushPending: () async {}),
      throwsA(
        isA<CloudLibraryConflictException>().having(
          (error) => error.reason,
          'reason',
          CloudLibraryConflictReason.missingManifest,
        ),
      ),
    );
    expect(client.snapshotUploads, 0);
    expect(client.namedUploads, 0);
  });

  test(
    'cloud restore cleans its staging file after applying the backup',
    () async {
      auth.session = _session();
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-cloud-restore-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final library = _CloudLibraryRepository(directory);
      final client = _WorkflowClient();
      final service = serviceWith(() => client);
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

CloudSyncSession _session() => const CloudSyncSession(
  serverUrl: 'https://dav.jianguoyun.com/dav/',
  username: 'writer@example.com',
  appPassword: 'app-password',
);

class _MemoryAuthStore extends CloudAuthSecureStore {
  CloudSyncSession? session;

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

class _CloudLibraryRepository implements WritingLibraryRepository {
  _CloudLibraryRepository(this.directory);

  final Directory directory;
  BackupKind? createdKind;
  var createCalls = 0;
  RestoreMode? restoredMode;
  String? restoredPath;
  bool restoredFileExisted = false;
  var hasArticles = true;
  var cloudLibraryId = 'library-id';

  @override
  Future<String> ensureCloudLibraryId() async => cloudLibraryId;

  @override
  Future<bool> hasArticleContent() async => hasArticles;

  @override
  Future<void> setCloudLibraryId(String id) async {
    cloudLibraryId = id;
  }

  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async {
    createCalls++;
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
  Future<LibraryMergeStats> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async {
    restoredMode = mode;
    restoredPath = entry.path;
    restoredFileExisted = await File(entry.path).exists();
    return const LibraryMergeStats(articlesAdded: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemorySettingsBundle extends CloudSettingsBundle {
  @override
  Future<List<int>> exportBytes() async => utf8.encode('{"schema":1,"files":{}}');

  @override
  Future<int> importBytes(List<int> bytes) async => 0;
}

class _WorkflowClient extends WebDavClient {
  CloudSyncSession? verifiedSession;
  bool failVerification = false;

  @override
  Future<void> verifyConnection(CloudSyncSession session) async {
    if (failVerification) throw StateError('credentials rejected');
    verifiedSession = session;
  }

  int namedUploads = 0;
  int snapshotUploads = 0;
  int settingsUploads = 0;
  int settingsDownloads = 0;
  final uploadOrder = <String>[];
  bool closed = false;
  bool untrackedContent = false;
  CloudSyncManifest? remoteManifest;
  final backups = <CloudBackupEntry>[];
  final deleted = <CloudBackupEntry>[];

  @override
  Future<List<CloudBackupEntry>> listNamedBackups({
    required CloudSyncSession session,
    required String libraryFolderId,
  }) async => [...backups]..sort((a, b) => b.modified.compareTo(a.modified));

  @override
  Future<void> deleteNamedBackup({
    required CloudSyncSession session,
    required CloudBackupEntry entry,
  }) async {
    deleted.add(entry);
  }

  @override
  Future<String> ensureLibraryFolder({
    required CloudSyncSession session,
  }) async => 'folder';

  @override
  Future<bool> hasUntrackedContent({
    required CloudSyncSession session,
    required String parentFileId,
  }) async => untrackedContent;

  @override
  Future<void> uploadNamedBackup({
    required CloudSyncSession session,
    required String libraryFolderId,
    required File pwb,
    required String fileName,
  }) async {
    expect(await pwb.exists(), isTrue);
    namedUploads++;
    uploadOrder.add('backup');
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
    uploadOrder.add('snapshot');
  }

  @override
  Future<void> uploadSettingsBundle({
    required CloudSyncSession session,
    required String parentFileId,
    required String fileName,
    required List<int> bytes,
  }) async {
    expect(bytes, isNotEmpty);
    expect(fileName, isNotEmpty);
    settingsUploads++;
    uploadOrder.add('settings');
  }

  @override
  Future<List<int>?> downloadSettingsBundle({
    required CloudSyncSession session,
    required String parentFileId,
    required String fileName,
    String? fallbackFileName,
  }) async {
    expect(fileName, isNotEmpty);
    settingsDownloads++;
    return utf8.encode('{"schema":1,"files":{}}');
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
