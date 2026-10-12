import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/cloud_auth_secure_store.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

void main() {
  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'cloud session round-trips through secure storage and can be cleared',
    () async {
      final store = CloudAuthSecureStore();
      final session = CloudSyncSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        expiresAt: DateTime.utc(2026, 1, 2),
        driveId: 'drive',
        displayName: 'Writer',
      );

      expect(await store.loadSession(), isNull);
      await store.saveSession(session);
      final restored = await store.loadSession();
      expect(restored?.accessToken, 'access');
      expect(restored?.refreshToken, 'refresh');
      expect(restored?.displayName, 'Writer');
      expect(
        restored?.expiresAt.millisecondsSinceEpoch,
        session.expiresAt.millisecondsSinceEpoch,
      );

      await store.clearSession();
      expect(await store.loadSession(), isNull);
    },
  );

  test(
    'app credentials require both nonempty values and survive sign out',
    () async {
      final store = CloudAuthSecureStore();
      await store.saveStoredAppCredentials(
        const AliyunDriveAppCredentials(clientId: 'id', clientSecret: ''),
      );
      expect(await store.loadStoredAppCredentials(), isNull);

      await store.saveStoredAppCredentials(
        const AliyunDriveAppCredentials(clientId: 'id', clientSecret: 'secret'),
      );
      await store.clearSession();
      final credentials = await store.loadStoredAppCredentials();
      expect(credentials?.clientId, 'id');
      expect(credentials?.clientSecret, 'secret');

      await store.clearStoredAppCredentials();
      expect(await store.loadStoredAppCredentials(), isNull);
    },
  );
}
