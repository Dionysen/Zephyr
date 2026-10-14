import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:zephyr/data/services/cloud_settings_bundle.dart';

void main() {
  test('exports and imports preference files under application support', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-settings-bundle-');
    addTearDown(() => root.delete(recursive: true));
    final theme = File(path.join(root.path, 'zephyr', 'theme-tokens.json'));
    await theme.parent.create(recursive: true);
    await theme.writeAsString('{"uiLocalePreference":"zh"}');

    final bundle = CloudSettingsBundle(
      supportDirectory: () async => root,
      platform: CloudSettingsPlatform.mobile,
    );
    final bytes = await bundle.exportBytes();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect(decoded['schema'], CloudSettingsBundle.schema);
    expect(decoded['platform'], 'mobile');
    expect(bundle.cloudFileName, 'settings-mobile.json');
    expect(bundle.legacyCloudFileNameFallback, isNull);
    expect(
      (decoded['files'] as Map)['zephyr/theme-tokens.json'],
      '{"uiLocalePreference":"zh"}',
    );

    final other = await Directory.systemTemp.createTemp('zephyr-settings-in-');
    addTearDown(() => other.delete(recursive: true));
    final importer = CloudSettingsBundle(supportDirectory: () async => other);
    final written = await importer.importBytes(bytes);
    expect(written, 1);
    expect(
      await File(
        path.join(other.path, 'zephyr', 'theme-tokens.json'),
      ).readAsString(),
      '{"uiLocalePreference":"zh"}',
    );
  });

  test('desktop platform uses settings-desktop with legacy fallback name', () {
    final bundle = CloudSettingsBundle(
      supportDirectory: () async => Directory.systemTemp,
      platform: CloudSettingsPlatform.desktop,
    );
    expect(bundle.cloudFileName, 'settings-desktop.json');
    expect(
      bundle.legacyCloudFileNameFallback,
      CloudSettingsPlatform.legacyCloudFileName,
    );
  });

  test('ignores path escape attempts in import', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-settings-safe-');
    addTearDown(() => root.delete(recursive: true));
    final bundle = CloudSettingsBundle(
      supportDirectory: () async => root,
      platform: CloudSettingsPlatform.desktop,
    );
    final written = await bundle.importJson({
      'schema': 1,
      'files': {
        '../evil.json': '{}',
        'zephyr/theme-tokens.json': '{"ok":true}',
      },
    });
    expect(written, 1);
    expect(File(path.join(root.path, 'evil.json')).existsSync(), isFalse);
  });
}
