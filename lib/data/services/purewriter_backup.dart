import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/library_backup.dart';
import 'purewriter_database.dart';

/// Locates, creates, and restores PureWriter `.pwb` backups (7z archives
/// containing a `*.db` snapshot of `App/Room.db`).
class PureWriterBackup {
  PureWriterBackup({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('zephyr/purewriter_backup');

  final MethodChannel _channel;

  static const autoKeepCount = 25;

  /// Newest `.pwb` under `{root}/Backups` (including `Backups/Auto`).
  File? findLatestBackup(Directory libraryRoot) {
    final entries = listBackupsAtPath(libraryRoot.path);
    return entries.isEmpty ? null : File(entries.first.path);
  }

  bool hasBackups(Directory libraryRoot) =>
      listBackupsAtPath(libraryRoot.path).isNotEmpty;

  /// Lists backups on a background isolate so directory walks do not jank UI.
  Future<List<BackupEntry>> listBackups(Directory libraryRoot) {
    final rootPath = libraryRoot.path;
    return Isolate.run(() => listBackupsAtPath(rootPath));
  }

  /// Packs [roomDb] into a new `.pwb` under `Backups/` or `Backups/Auto/`.
  Future<BackupEntry> createPwb({
    required Directory libraryRoot,
    required File roomDb,
    required BackupKind kind,
    required BackupFileLabel label,
  }) async {
    final backupsDir = Directory(path.join(libraryRoot.path, 'Backups'));
    final targetDir = kind == BackupKind.automatic
        ? Directory(path.join(backupsDir.path, 'Auto'))
        : backupsDir;
    await targetDir.create(recursive: true);
    final fileName = label.toFileName();
    final pwbPath = path.join(targetDir.path, fileName);
    await _packRoomDb(roomDbPath: roomDb.path, pwbPath: pwbPath);
    if (kind == BackupKind.automatic) {
      await pruneAutomaticBackups(libraryRoot, keep: autoKeepCount);
    }
    final kindIndex = kind.index;
    return Isolate.run(() {
      final pwb = File(pwbPath);
      final stat = pwb.statSync();
      return BackupEntry(
        path: pwb.path,
        fileName: path.basename(pwb.path),
        modified: stat.modified,
        sizeBytes: stat.size,
        kind: BackupKind.values[kindIndex],
      );
    });
  }

  Future<void> pruneAutomaticBackups(
    Directory libraryRoot, {
    int keep = autoKeepCount,
  }) {
    final rootPath = libraryRoot.path;
    return Isolate.run(() => pruneAutomaticBackupsAtPath(rootPath, keep));
  }

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
    await _restoreWithBsdtar(pwb.path, destinationRoomDb.path);
  }

  /// Extracts the `.db` from [pwb] into a temp file and returns it.
  Future<File> extractRoomDbToTemp(File pwb) async {
    final staging = await Directory.systemTemp.createTemp('zephyr-pwb-extract-');
    final destination = File(path.join(staging.path, 'Room.db'));
    await restoreRoomDb(pwb: pwb, destinationRoomDb: destination);
    return destination;
  }

  Future<void> _packRoomDb({
    required String roomDbPath,
    required String pwbPath,
  }) async {
    if (Platform.isAndroid) {
      // Native side compresses on a background executor.
      await _channel.invokeMethod<void>('createPwb', {
        'roomDbPath': roomDbPath,
        'pwbPath': pwbPath,
      });
      return;
    }
    final staging = await Directory.systemTemp.createTemp('zephyr-pack-pwb-');
    try {
      const dbName = 'PureWriterBackup.db';
      final stagedDb = path.join(staging.path, dbName);
      final stagingPath = staging.path;
      await Isolate.run(() {
        File(roomDbPath).copySync(stagedDb);
        final out = File(pwbPath);
        if (out.existsSync()) out.deleteSync();
      });
      final packed = await Process.run('bsdtar', [
        '--format',
        '7zip',
        '-cf',
        pwbPath,
        '-C',
        stagingPath,
        dbName,
      ]);
      if (packed.exitCode != 0) {
        throw StateError('Could not create PureWriter backup: ${packed.stderr}');
      }
    } finally {
      await staging.delete(recursive: true);
    }
  }

  Future<void> _restoreWithBsdtar(String pwbPath, String destinationPath) async {
    final staging = await Directory.systemTemp.createTemp('zephyr-pwb-');
    try {
      final listed = await Process.run('bsdtar', ['-tf', pwbPath]);
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
        pwbPath,
        '-C',
        staging.path,
        dbEntry,
      ]);
      if (extracted.exitCode != 0) {
        throw StateError(
          'Could not extract PureWriter backup: ${extracted.stderr}',
        );
      }
      final sourcePath = path.join(staging.path, dbEntry);
      await Isolate.run(() {
        final source = File(sourcePath);
        if (!source.existsSync()) {
          throw StateError('Extracted backup database was not found.');
        }
        source.copySync(destinationPath);
      });
    } finally {
      await staging.delete(recursive: true);
    }
  }

}

/// Sync listing used from [Isolate.run] and open-library restore heuristics.
List<BackupEntry> listBackupsAtPath(String libraryRootPath) {
  final libraryRoot = Directory(libraryRootPath);
  final backups = findChildDirectory(libraryRoot, 'backups');
  if (backups == null) return const [];
  final files = <File>[];
  _collectPwb(backups, files);
  files.sort(
    (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
  );
  return [
    for (final file in files) _backupEntryFor(file, backups),
  ];
}

void pruneAutomaticBackupsAtPath(String libraryRootPath, int keep) {
  final backups =
      findChildDirectory(Directory(libraryRootPath), 'backups') ??
      Directory(path.join(libraryRootPath, 'Backups'));
  final auto = findChildDirectory(backups, 'auto');
  if (auto == null || !auto.existsSync()) return;
  final files = auto
      .listSync(followLinks: false)
      .whereType<File>()
      .where((f) => path.extension(f.path).toLowerCase() == '.pwb')
      .toList()
    ..sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
  for (var i = keep; i < files.length; i++) {
    try {
      files[i].deleteSync();
    } on Object {
      // Best-effort cleanup.
    }
  }
}

BackupEntry _backupEntryFor(File file, Directory backupsRoot) {
  final stat = file.statSync();
  return BackupEntry(
    path: file.path,
    fileName: path.basename(file.path),
    modified: stat.modified,
    sizeBytes: stat.size,
    kind: _backupKindFor(file, backupsRoot),
  );
}

BackupKind _backupKindFor(File file, Directory backupsRoot) {
  final parent = file.parent;
  if (path.equals(parent.path, backupsRoot.path)) {
    return BackupKind.manual;
  }
  final name = path.basename(parent.path).toLowerCase();
  return name == 'auto' ? BackupKind.automatic : BackupKind.manual;
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
