import 'dart:io';

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
    final entries = listBackups(libraryRoot);
    return entries.isEmpty ? null : File(entries.first.path);
  }

  bool hasBackups(Directory libraryRoot) =>
      listBackups(libraryRoot).isNotEmpty;

  /// All `.pwb` files, newest first.
  List<BackupEntry> listBackups(Directory libraryRoot) {
    final backups = findChildDirectory(libraryRoot, 'backups');
    if (backups == null) return const [];
    final files = <File>[];
    _collectPwb(backups, files);
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return [
      for (final file in files)
        BackupEntry(
          path: file.path,
          fileName: path.basename(file.path),
          modified: file.statSync().modified,
          sizeBytes: file.lengthSync(),
          kind: _kindFor(file, backups),
        ),
    ];
  }

  BackupKind _kindFor(File file, Directory backupsRoot) {
    final parent = file.parent;
    if (path.equals(parent.path, backupsRoot.path)) {
      return BackupKind.manual;
    }
    final name = path.basename(parent.path).toLowerCase();
    return name == 'auto' ? BackupKind.automatic : BackupKind.manual;
  }

  /// Packs [roomDb] into a new `.pwb` under `Backups/` or `Backups/Auto/`.
  Future<BackupEntry> createPwb({
    required Directory libraryRoot,
    required File roomDb,
    required BackupKind kind,
  }) async {
    final backupsDir = Directory(path.join(libraryRoot.path, 'Backups'));
    final targetDir = kind == BackupKind.automatic
        ? Directory(path.join(backupsDir.path, 'Auto'))
        : backupsDir;
    await targetDir.create(recursive: true);
    final stamp = _fileStamp(DateTime.now());
    final pwb = File(path.join(targetDir.path, 'Zephyr-$stamp.pwb'));
    await _packRoomDb(roomDb: roomDb, pwb: pwb);
    if (kind == BackupKind.automatic) {
      await pruneAutomaticBackups(libraryRoot, keep: autoKeepCount);
    }
    final stat = pwb.statSync();
    return BackupEntry(
      path: pwb.path,
      fileName: path.basename(pwb.path),
      modified: stat.modified,
      sizeBytes: stat.size,
      kind: kind,
    );
  }

  Future<void> pruneAutomaticBackups(
    Directory libraryRoot, {
    int keep = autoKeepCount,
  }) async {
    final auto = findChildDirectory(
      findChildDirectory(libraryRoot, 'backups') ??
          Directory(path.join(libraryRoot.path, 'Backups')),
      'auto',
    );
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
        await files[i].delete();
      } on Object {
        // Best-effort cleanup.
      }
    }
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
    await _restoreWithBsdtar(pwb, destinationRoomDb);
  }

  /// Extracts the `.db` from [pwb] into a temp file and returns it.
  Future<File> extractRoomDbToTemp(File pwb) async {
    final staging = await Directory.systemTemp.createTemp('zephyr-pwb-extract-');
    final destination = File(path.join(staging.path, 'Room.db'));
    await restoreRoomDb(pwb: pwb, destinationRoomDb: destination);
    return destination;
  }

  Future<void> _packRoomDb({required File roomDb, required File pwb}) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('createPwb', {
        'roomDbPath': roomDb.path,
        'pwbPath': pwb.path,
      });
      return;
    }
    final staging = await Directory.systemTemp.createTemp('zephyr-pack-pwb-');
    try {
      final dbName = 'PureWriterBackup.db';
      await roomDb.copy(path.join(staging.path, dbName));
      if (await pwb.exists()) {
        await pwb.delete();
      }
      final packed = await Process.run('bsdtar', [
        '--format',
        '7zip',
        '-cf',
        pwb.path,
        '-C',
        staging.path,
        dbName,
      ]);
      if (packed.exitCode != 0) {
        throw StateError('Could not create PureWriter backup: ${packed.stderr}');
      }
    } finally {
      await staging.delete(recursive: true);
    }
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

  String _fileStamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}-'
        '${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }
}
