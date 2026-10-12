import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/cloud_sync_service.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';
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

  test('manual sync and backup require a signed-in session', () async {
    await model.syncNow();
    expect(model.error, isA<StateError>());
    await model.backupNow();
    expect(model.error, isA<StateError>());
    expect(service.syncCalls, 0);
    expect(service.backupCalls, 0);
  });

  test(
    'cloud backup reports busy and clears it after the service returns',
    () async {
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

  test('login challenge can be cancelled before the next poll', () async {
    await model.beginLogin();
    expect(model.isLoggingIn, isTrue);
    expect(model.qrChallenge?.sid, 'sid');
    expect(model.qrStatus, AliyunDriveQrStatus.waiting);

    model.cancelLogin();
    expect(model.busy, isFalse);
    expect(model.qrChallenge, isNull);
    expect(model.qrStatus, isNull);
  });

  testWidgets('successful QR poll completes login and dismisses challenge', (
    tester,
  ) async {
    await model.beginLogin();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(service.completedCode, 'auth-code');
    expect(model.isSignedIn, isTrue);
    expect(model.busy, isFalse);
    expect(model.qrChallenge, isNull);
  });
}

class _UnusedLibraryRepository implements WritingLibraryRepository {
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
  bool failLoad = false;
  int syncCalls = 0;
  int backupCalls = 0;
  int listCalls = 0;
  String? completedCode;

  @override
  bool get isSignedIn => signedIn;

  @override
  CloudSyncPreferences get preferences => CloudSyncPreferences.defaults;

  @override
  Future<void> load() async {
    if (failLoad) throw StateError('load failed');
  }

  @override
  Future<AliyunDriveQrChallenge> beginQrLogin() async =>
      const AliyunDriveQrChallenge(
        sid: 'sid',
        qrCodeUrl: 'https://example.test/qr',
      );

  @override
  Future<AliyunDriveQrPollResult> pollQrLogin(String sid) async =>
      const AliyunDriveQrPollResult(
        status: AliyunDriveQrStatus.success,
        authCode: 'auth-code',
      );

  @override
  Future<CloudSyncSession> completeQrLogin(String authCode) async {
    completedCode = authCode;
    signedIn = true;
    return CloudSyncSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      driveId: 'drive',
    );
  }

  @override
  Future<CloudBackupEntry> backupNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
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
  Future<CloudSyncManifest> syncNow({
    required WritingLibraryRepository library,
    required Future<void> Function() flushPending,
  }) async {
    syncCalls++;
    throw StateError('unexpected sync');
  }
}
