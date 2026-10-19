import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/folder_bookmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('zephyr/test_folder_bookmark');

  test(
    'folder picker returns a selected path and an optional bookmark',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'pickDirectory');
        return {'path': '/writing', 'bookmark': 'encoded'};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final picked = await FolderBookmarkAccess(channel: channel)
          .pickDirectory();
      expect(picked?.path, '/writing');
      expect(picked?.bookmark, 'encoded');
    },
  );

  test(
    'folder picker treats missing paths and blank bookmarks as absent',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        return calls == 1 ? {'path': ''} : {'path': '/writing', 'bookmark': ''};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      final access = FolderBookmarkAccess(channel: channel);
      expect(await access.pickDirectory(), isNull);
      expect((await access.pickDirectory())?.bookmark, isNull);
    },
  );

  test(
    'restoring a bookmark passes the token through the platform channel',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'resolve');
        expect(call.arguments, 'encoded');
        return '/writing';
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      expect(
        await FolderBookmarkAccess(channel: channel).restore('encoded'),
        '/writing',
      );
    },
  );
}
