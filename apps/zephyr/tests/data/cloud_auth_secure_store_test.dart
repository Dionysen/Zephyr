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
        serverUrl: 'https://dav.jianguoyun.com/dav/',
        username: 'writer@example.com',
        appPassword: 'app-password',
      );

      expect(await store.loadSession(), isNull);
      await store.saveSession(session);
      final restored = await store.loadSession();
      expect(restored?.serverUrl, session.serverUrl);
      expect(restored?.username, session.username);
      expect(restored?.appPassword, session.appPassword);

      await store.clearSession();
      expect(await store.loadSession(), isNull);
    },
  );
}
