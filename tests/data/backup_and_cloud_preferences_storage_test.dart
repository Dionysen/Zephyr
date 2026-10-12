import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/aliyun_drive_config.dart';
import 'package:zephyr/data/services/backup_preferences_file_storage.dart';
import 'package:zephyr/data/services/cloud_sync_preferences_storage.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zephyr-backup-cloud-');
    addTearDown(() => directory.delete(recursive: true));
  });

  test('backup preferences load defaults, persist values, and tolerate corrupt JSON', () async {
    final storage = BackupPreferencesFileStorage(
      supportDirectory: () async => directory,
    );
    expect((await storage.load()).autoBackupEnabled, isTrue);

    final timestamp = DateTime.utc(2026, 4, 10, 12);
    await storage.save(
      BackupPreferences(autoBackupEnabled: false, lastAutoBackupAt: timestamp),
    );
    final saved = await storage.load();
    expect(saved.autoBackupEnabled, isFalse);
    expect(
      saved.lastAutoBackupAt?.millisecondsSinceEpoch,
      timestamp.millisecondsSinceEpoch,
    );

    await File('${directory.path}/zephyr/backup_preferences.json')
        .writeAsString('{invalid');
    expect(
      (await storage.load()).autoBackupEnabled,
      BackupPreferences.defaults.autoBackupEnabled,
    );
  });

  test(
    'cloud sync preferences load defaults and recover from corrupt JSON',
    () async {
      final storage = CloudSyncPreferencesStorage(
        supportDirectory: () async => directory,
      );
      expect(await storage.load(), isA<CloudSyncPreferences>());

      await File('${directory.path}/zephyr/cloud_sync_preferences.json')
          .writeAsString('[]');
      final recovered = await storage.load();
      expect(recovered.toJson(), CloudSyncPreferences.defaults.toJson());
    },
  );

  test(
    'stored Aliyun credentials override configured fallback independently',
    () {
      const config = AliyunDriveConfig(
        dartDefineClientId: 'defined-id',
        dartDefineClientSecret: 'defined-secret',
      );
      final actual = config.fromStored(
        storedClientId: 'stored-id',
        storedClientSecret: '',
      );
      expect(actual.clientId, 'stored-id');
      expect(actual.clientSecret, 'defined-secret');
      expect(actual.isConfigured, isTrue);
    },
  );
}
