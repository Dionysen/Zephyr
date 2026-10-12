import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

void main() {
  test('CloudSyncSession round-trips JSON', () {
    final session = CloudSyncSession(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2026, 4, 10, 12),
      driveId: 'drive',
      displayName: 'L',
      avatarUrl: 'https://example.com/a.png',
    );
    final restored = CloudSyncSession.fromJson(session.toJson());
    expect(restored, isNotNull);
    expect(restored!.accessToken, 'a');
    expect(restored.refreshToken, 'r');
    expect(restored.driveId, 'drive');
    expect(restored.displayName, 'L');
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

  test('AliyunDriveAppCredentials isConfigured', () {
    expect(
      const AliyunDriveAppCredentials(clientId: '', clientSecret: 'x')
          .isConfigured,
      isFalse,
    );
    expect(
      const AliyunDriveAppCredentials(clientId: 'id', clientSecret: 'secret')
          .isConfigured,
      isTrue,
    );
  });
}
