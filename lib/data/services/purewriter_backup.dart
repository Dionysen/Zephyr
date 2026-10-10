import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:koni_archive/io.dart';
import 'package:path/path.dart' as path;

import '../../domain/models/library_backup.dart';
import 'purewriter_database.dart';

/// Locates, creates, and restores PureWriter `.pwb` backups (7z archives
/// containing a `*.db` snapshot of `App/Room.db`).
///
/// Pack/extract uses pure-Dart [koni_archive] (no system `bsdtar`, no native
/// 7z channel).
class PureWriterBackup {
  PureWriterBackup();

  static const autoKeepCount = 25;
  static const _dbEntryName = 'PureWriterBackup.db';

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
    await packRoomDbToPwb(roomDbPath: roomDb.path, pwbPath: pwbPath);
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
    await extractDbFromPwb(
      pwbPath: pwb.path,
      destinationPath: destinationRoomDb.path,
    );
  }

  /// Extracts the `.db` from [pwb] into a temp file and returns it.
  Future<File> extractRoomDbToTemp(File pwb) async {
    final staging = await Directory.systemTemp.createTemp('zephyr-pwb-extract-');
    final destination = File(path.join(staging.path, 'Room.db'));
    await restoreRoomDb(pwb: pwb, destinationRoomDb: destination);
    return destination;
  }
}

/// Packs [roomDbPath] into a 7z `.pwb` at [pwbPath] (CPU work on a worker isolate).
Future<void> packRoomDbToPwb({
  required String roomDbPath,
  required String pwbPath,
}) => Isolate.run(() => _packRoomDbSync(roomDbPath, pwbPath));

/// Extracts the first `*.db` entry from [pwbPath] to [destinationPath].
Future<void> extractDbFromPwb({
  required String pwbPath,
  required String destinationPath,
}) => Isolate.run(() => _extractDbSync(pwbPath, destinationPath));

Future<void> _packRoomDbSync(String roomDbPath, String pwbPath) async {
  final room = File(roomDbPath);
  if (!room.existsSync()) {
    throw StateError('Room database not found: $roomDbPath');
  }
  final out = File(pwbPath);
  if (out.existsSync()) {
    out.deleteSync();
  }
  final size = room.lengthSync();
  final writer = await createArchiveFile(
    pwbPath,
    format: const SevenZWriteFormat(),
  );
  try {
    await writer.addStream(
      ArchiveEntrySpec(path: PureWriterBackup._dbEntryName),
      room.openRead().map(
        (chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk),
      ),
      size: size,
    );
  } finally {
    await writer.close();
  }
}

Future<void> _extractDbSync(String pwbPath, String destinationPath) async {
  final archive = await openArchiveFile(pwbPath);
  try {
    ArchiveEntry? entry;
    for (final candidate in archive.entries) {
      if (candidate.type == ArchiveEntryType.file &&
          candidate.path.toLowerCase().endsWith('.db')) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) {
      throw StateError('PureWriter backup contains no .db database.');
    }
    final out = File(destinationPath);
    out.parent.createSync(recursive: true);
    final sink = out.openWrite();
    try {
      await for (final chunk in archive.openRead(entry)) {
        sink.add(chunk);
      }
    } finally {
      await sink.close();
    }
  } finally {
    await archive.close();
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
