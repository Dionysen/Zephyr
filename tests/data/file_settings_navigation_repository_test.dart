import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_settings_navigation_repository.dart';
import 'package:zephyr/data/services/settings_navigation_file_storage.dart';
import 'package:zephyr/domain/models/settings_section.dart';

void main() {
  test(
    'round-trips the last settings group through app-support storage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-settings-nav-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FileSettingsNavigationRepository(
        SettingsNavigationFileStorage(directoryProvider: () async => directory),
      );

      await repository.save(SettingsSection.editor);
      final actual = await repository.load();

      expect(actual, SettingsSection.editor);
    },
  );

  test('falls back to theme when the stored group is unknown', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-settings-nav-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = SettingsNavigationFileStorage(
      directoryProvider: () async => directory,
    );
    await storage.write({'section': 'missing'});
    final actual = await FileSettingsNavigationRepository(storage).load();

    expect(actual, SettingsSection.theme);
  });
}
