import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_json_store/local_json_store.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'JSON map store uses an injected directory and creates parent folders',
    () async {
      final root = await Directory.systemTemp.createTemp('json-map-store-');
      addTearDown(() => root.delete(recursive: true));
      final store = JsonMapFileStore(
        directoryProvider: () async => root,
        relativePath: path.join('another-app', 'settings.json'),
        invalidMessage: 'Invalid settings.',
      );

      expect(await store.read(), isNull);
      await store.write({'scale': 1.5, 'enabled': true});

      expect(await store.read(), {'scale': 1.5, 'enabled': true});
      expect(
        await File(path.join(root.path, 'another-app', 'settings.json'))
            .exists(),
        isTrue,
      );
    },
  );

  test(
    'JSON map store reports a non-object document with caller text',
    () async {
      final root = await Directory.systemTemp.createTemp('json-map-store-');
      addTearDown(() => root.delete(recursive: true));
      final file = File(path.join(root.path, 'settings.json'));
      await file.writeAsString('[]');
      final store = JsonMapFileStore(
        directoryProvider: () async => root,
        relativePath: 'settings.json',
        invalidMessage: 'Invalid settings.',
      );

      await expectLater(
        store.read(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Invalid settings.',
          ),
        ),
      );
    },
  );
}
