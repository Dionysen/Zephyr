import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'purewriter_database.dart';

/// Locates and restores PureWriter `.pwb` backups (7z archives containing a
/// `*.db` snapshot of `App/Room.db`).
class PureWriterBackup {
  PureWriterBackup({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('zephyr/purewriter_backup');

  final MethodChannel _channel;

  /// Newest `.pwb` under `{root}/Backups` (including `Backups/Auto`).
  File? findLatestBackup(Directory libraryRoot) {
    final backups = findChildDirectory(libraryRoot, 'backups');
    if (backups == null) return null;
    final files = <File>[];
    _collectPwb(backups, files);
    if (files.isEmpty) return null;
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files.first;
  }

  bool hasBackups(Directory libraryRoot) => findLatestBackup(libraryRoot) != null;

  /// Extracts the database from [pwb] into [destinationRoomDb].
  Future<void> restoreRoomDb({
    required File pwb,
    required File destinationRoomDb,
  }) async {
    await destinationRoomDb.parent.create(recursive: true);
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('restorePwb', {
        'pwbPath': pwb.path,
        'destinationPath': destinationRoomDb.path,
      });
      return;
    }
    await _restoreWithBsdtar(pwb, destinationRoomDb);
  }

  Future<void> _restoreWithBsdtar(File pwb, File destinationRoomDb) async {
    final staging = await Directory.systemTemp.createTemp('zephyr-pwb-');
    try {
      final listed = await Process.run('bsdtar', ['-tf', pwb.path]);
      if (listed.exitCode != 0) {
        throw StateError('Could not read PureWriter backup: ${listed.stderr}');
      }
      final entries = (listed.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.toLowerCase().endsWith('.db'))
          .toList(growable: false);
      if (entries.isEmpty) {
        throw StateError('PureWriter backup contains no .db database.');
      }
      final dbEntry = entries.first;
      final extracted = await Process.run('bsdtar', [
        '-xf',
        pwb.path,
        '-C',
        staging.path,
        dbEntry,
      ]);
      if (extracted.exitCode != 0) {
        throw StateError(
          'Could not extract PureWriter backup: ${extracted.stderr}',
        );
      }
      final source = File(path.join(staging.path, dbEntry));
      if (!source.existsSync()) {
        throw StateError('Extracted backup database was not found.');
      }
      await source.copy(destinationRoomDb.path);
    } finally {
      await staging.delete(recursive: true);
    }
  }

  void _collectPwb(Directory dir, List<File> out) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is Directory) {
        _collectPwb(entity, out);
      } else if (entity is File &&
          path.extension(entity.path).toLowerCase() == '.pwb') {
        out.add(entity);
      }
    }
  }
}
