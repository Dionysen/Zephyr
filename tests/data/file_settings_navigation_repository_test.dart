import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_settings_navigation_repository.dart';
import 'package:zephyr/data/services/settings_navigation_file_storage.dart';
import 'package:zephyr/domain/models/settings_navigation.dart';
import 'package:zephyr/domain/models/settings_section.dart';

void main() {
  test('round-trips the last settings group and sidebar width', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-settings-nav-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileSettingsNavigationRepository(
      SettingsNavigationFileStorage(directoryProvider: () async => directory),
    );

    await repository.save(
      const SettingsNavigation(
        section: SettingsSection.editor,
        sidebarWidth: 312,
      ),
    );
    final actual = await repository.load();

    expect(actual.section, SettingsSection.editor);
    expect(actual.sidebarWidth, 312);
  });

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

    expect(actual.section, SettingsSection.theme);
    expect(actual.sidebarWidth, SettingsNavigation.defaultSidebarWidth);
  });

  test('clamps an out-of-range stored sidebar width', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-settings-nav-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final storage = SettingsNavigationFileStorage(
      directoryProvider: () async => directory,
    );
    await storage.write({'section': 'editor', 'sidebarWidth': 12});
    final actual = await FileSettingsNavigationRepository(storage).load();

    expect(actual.section, SettingsSection.editor);
    expect(actual.sidebarWidth, SettingsNavigation.minSidebarWidth);
  });
}
