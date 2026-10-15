import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

void main() {
  test('CloudSyncSession round-trips JSON', () {
    final session = CloudSyncSession(
      serverUrl: 'https://dav.jianguoyun.com/dav/',
      username: 'writer@example.com',
      appPassword: 'app-password',
    );
    final restored = CloudSyncSession.fromJson(session.toJson());
    expect(restored, isNotNull);
    expect(restored!.serverUrl, 'https://dav.jianguoyun.com/dav/');
    expect(restored.username, 'writer@example.com');
    expect(restored.appPassword, 'app-password');
  });

  test('CloudSyncManifest round-trips JSON', () {
    final manifest = CloudSyncManifest(
      libraryId: 'lib-1',
      updatedAt: DateTime.utc(2026, 4, 10, 12),
      deviceName: 'Pixel',
      appVersion: '0.1.0',
    );
    final restored = CloudSyncManifest.fromJson(manifest.toJson());
    expect(restored, isNotNull);
    expect(restored!.libraryId, 'lib-1');
    expect(restored.deviceName, 'Pixel');
    expect(restored.appVersion, '0.1.0');
  });

  test('CloudSyncPreferences defaults enable cloud backup', () {
    expect(CloudSyncPreferences.defaults.cloudBackupEnabled, isTrue);
    final restored = CloudSyncPreferences.fromJson(const {});
    expect(restored.cloudBackupEnabled, isTrue);
  });

  test('CloudSyncPreferences ignores legacy automatic sync preference', () {
    final restored = CloudSyncPreferences.fromJson(const {
      'autoSyncEnabled': true,
      'cloudBackupEnabled': false,
    });
    expect(restored.cloudBackupEnabled, isFalse);
    expect(restored.toJson(), isNot(contains('autoSyncEnabled')));
  });

  test('CloudSyncPreferences round-trips cloudBackupEnabled off', () {
    final prefs = const CloudSyncPreferences(cloudBackupEnabled: false);
    final restored = CloudSyncPreferences.fromJson(prefs.toJson());
    expect(restored.cloudBackupEnabled, isFalse);
  });

  test('CloudSyncPreferences round-trips pendingCloudBackup', () {
    final prefs = const CloudSyncPreferences(pendingCloudBackup: true);
    final restored = CloudSyncPreferences.fromJson(prefs.toJson());
    expect(restored.pendingCloudBackup, isTrue);
    expect(
      CloudSyncPreferences.fromJson(const {}).pendingCloudBackup,
      isFalse,
    );
  });

  test('CloudSyncSession rejects incomplete stored credentials', () {
    expect(
      CloudSyncSession.fromJson(const {
        'serverUrl': 'https://dav.jianguoyun.com/dav/',
        'username': 'writer@example.com',
        'appPassword': '',
      }),
      isNull,
    );
  });
}
