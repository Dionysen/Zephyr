import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:zephyr/data/services/purewriter_backup.dart';
import 'package:zephyr/domain/models/library_backup.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zephyr-pwb-test-');
    addTearDown(() => directory.delete(recursive: true));
  });

  test('backup listing separates manual and automatic files and sorts newest first', () async {
    final backups = Directory(path.join(directory.path, 'Backups'));
    final auto = Directory(path.join(backups.path, 'Auto'));
    await auto.create(recursive: true);
    final manual = File(path.join(backups.path, 'manual.pwb'));
    final automatic = File(path.join(auto.path, 'automatic.PWB'));
    await manual.writeAsString('manual');
    await automatic.writeAsString('auto');
    await File('${auto.path}/ignore.txt').writeAsString('ignore');
    await manual.setLastModified(DateTime.utc(2026, 1, 1));
    await automatic.setLastModified(DateTime.utc(2026, 1, 2));

    final entries = await PureWriterBackup().listBackups(directory);

    expect(entries.map((entry) => entry.fileName), [
      'automatic.PWB',
      'manual.pwb',
    ]);
    expect(entries.map((entry) => entry.kind), [
      BackupKind.automatic,
      BackupKind.manual,
    ]);
    expect(
      PureWriterBackup().findLatestBackup(directory)?.path,
      automatic.path,
    );
  });

  test('automatic backup pruning keeps the newest requested count', () async {
    final auto = Directory('${directory.path}/Backups/Auto');
    await auto.create(recursive: true);
    for (var day = 1; day <= 4; day++) {
      final file = File('${auto.path}/$day.pwb');
      await file.writeAsString('$day');
      await file.setLastModified(DateTime.utc(2026, 1, day));
    }

    await PureWriterBackup().pruneAutomaticBackups(directory, keep: 2);

    expect(await File('${auto.path}/1.pwb').exists(), isFalse);
    expect(await File('${auto.path}/2.pwb').exists(), isFalse);
    expect(await File('${auto.path}/3.pwb').exists(), isTrue);
    expect(await File('${auto.path}/4.pwb').exists(), isTrue);
  });

  test('packed database can be restored without changing its bytes', () async {
    final room = File('${directory.path}/Room.db');
    final restored = File('${directory.path}/restore/Room.db');
    final archive = File('${directory.path}/backup.pwb');
    final bytes = List<int>.generate(1024, (index) => index % 256);
    await room.writeAsBytes(bytes);

    await packRoomDbToPwb(roomDbPath: room.path, pwbPath: archive.path);
    await PureWriterBackup().restoreRoomDb(
      pwb: archive,
      destinationRoomDb: restored,
    );

    expect(await restored.readAsBytes(), bytes);
  });

  test('packing a missing database reports a clear error', () async {
    await expectLater(
      packRoomDbToPwb(
        roomDbPath: '${directory.path}/missing.db',
        pwbPath: '${directory.path}/backup.pwb',
      ),
      throwsStateError,
    );
  });
}
