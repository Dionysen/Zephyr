import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/cloud_sync_service.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/l10n/app_localizations_en.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/cloud_sync_view_model.dart';

void main() {
  late _CloudService service;
  late LibraryViewModel library;
  late CloudSyncViewModel model;

  setUp(() {
    service = _CloudService();
    library = LibraryViewModel(_UnusedLibraryRepository());
    model = CloudSyncViewModel(library: library, service: service);
    addTearDown(() {
      model.dispose();
      library.dispose();
    });
  });

  test(
    'load exposes service failures and a later success clears the error',
    () async {
      service.failLoad = true;
      await model.load();
      expect(model.error, isA<StateError>());

      service.failLoad = false;
      await model.load();
      expect(model.error, isNull);
    },
  );

  test(
    'manual sync and backup require cloud backup and a signed-in session',
    () async {
      await model.syncNow();
      expect(model.error, isA<StateError>());
      await model.backupNow();
      expect(model.error, isA<StateError>());
      expect(service.pullCalls, 0);
      expect(service.backupCalls, 0);

      service.signedIn = true;
      await model.backupNow();
      expect(model.error, isA<StateError>());
      expect(service.backupCalls, 0);
    },
  );

  test(
    'cloud backup reports busy and clears it after the service returns',
    () async {
      service.cloudBackupOn = true;
      service.signedIn = true;
      await model.backupNow();

      expect(service.backupCalls, 1);
      expect(model.busy, isFalse);
      expect(model.error, isNull);
    },
  );

  test(
    'refresh returns no backups when signed out and clears stale results',
    () async {
      service.cloudBackupOn = true;
      service.signedIn = true;
      await model.refreshCloudBackups();
      expect(model.cloudBackups, [_CloudService.entry]);

      service.signedIn = false;
      final result = await model.refreshCloudBackups();
      expect(result, isEmpty);
      expect(model.cloudBackups, isEmpty);
      expect(service.listCalls, 1);
    },
  );

  test('connecting saves WebDAV credentials and clears busy state', () async {
    await model.connect(
      serverUrl: 'https://dav.jianguoyun.com/dav/',
      username: 'writer@example.com',
      appPassword: 'app-password',
    );

    expect(service.connectedSession?.username, 'writer@example.com');
    expect(model.isSignedIn, isTrue);
    expect(model.busy, isFalse);
    expect(model.error, isNull);
  });

  test('explains a library conflict after automatic sync', () async {
    service.cloudBackupOn = true;
    service.signedIn = true;
    service.pullFailure = const CloudLibraryConflictException(
      CloudLibraryConflictReason.anotherLibrary,
    );

    await model.maybeAutoSync();

    expect(service.pullCalls, 1);
    expect(model.error, isA<CloudLibraryConflictException>());
    expect(
      model.errorMessage(AppLocalizationsEn()),
      contains('Choose the original local directory'),
    );
  });

  test('maybeAutoSync skips when cloud backup is disabled', () async {
    service.signedIn = true;
    service.cloudBackupOn = false;
    await model.maybeAutoSync();
    expect(service.pullCalls, 0);
  });
}

class _UnusedLibraryRepository implements WritingLibraryRepository {
  @override
  LibraryLocation? get location => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CloudService extends CloudSyncService {
  static final entry = CloudBackupEntry(
    fileId: 'one',
    fileName: 'one.pwb',
    modified: DateTime.utc(2026, 1, 1),
    sizeBytes: 10,
  );
  bool signedIn = false;
  bool cloudBackupOn = false;
  bool failLoad = false;
  int pullCalls = 0;
  int backupCalls = 0;
  int listCalls = 0;
  Object? pullFailure;
  CloudSyncSession? connectedSession;

  @override
  bool get isSignedIn => signedIn;

  @override
  bool get cloudBackupEnabled => cloudBackupOn;

  @override
  CloudSyncPreferences get preferences =>
      CloudSyncPreferences(cloudBackupEnabled: cloudBackupOn);

  @override
  Future<void> load() async {
    if (failLoad) throw StateError('load failed');
  }

  @override
  Future<void> connect(CloudSyncSession session) async {
    connectedSession = session;
    signedIn = true;
  }

  @override
  Future<CloudBackupEntry> backupNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
    BackupKind kind = BackupKind.manual,
  }) async {
    backupCalls++;
    return entry;
  }

  @override
  Future<List<CloudBackupEntry>> listCloudBackups({
    required WritingLibraryRepository library,
  }) async {
    listCalls++;
    return [entry];
  }

  @override
  Future<CloudSyncManifest?> pullIfNewer({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    pullCalls++;
    final failure = pullFailure;
    if (failure != null) throw failure;
    return null;
  }
}
