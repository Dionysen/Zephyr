import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models/purewriter_models.dart';
import 'purewriter_backup.dart';

/// Owns one PureWriter library connection and its cross-process `.zephyr-lock`.
class PureWriterDatabase {
  PureWriterDatabase({
    Future<Directory> Function()? supportDirectory,
    PureWriterBackup? backups,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _backups = backups ?? PureWriterBackup();
  static const defaultFolderId = 'Default';
  static const trashFolderId = WritingFolder.trashId;
  static const identityHash = 'af22c7c534a04acc4530d670ac9e43c4';
  final Future<Directory> Function() _supportDirectory;
  final PureWriterBackup _backups;
  Database? _database;
  RandomAccessFile? _lock;
  LibraryLocation? _location;
  LibraryLocation? get location => _location;
  Database get database =>
      _database ?? (throw StateError('No PureWriter library is open.'));
  bool get writesAllowed => _location?.schema.writesAllowed ?? false;

  Future<LibraryLocation> openDefaultLibrary() async =>
      openLibrary((await _supportDirectory()).path, createIfMissing: true);

  /// Opens a PureWriter library root.
  ///
  /// Accepted layouts (Android / desktop PureWriter):
  /// - `{root}/App/Room.db` with optional `{root}/Backups/`
  /// - selecting the `App` directory itself
  ///
  /// Directory names are matched case-insensitively so Android `App` +
  /// `Backups` trees open the same way as desktop libraries.
  ///
  /// When `App/Room.db` is missing but `Backups/*.pwb` exist, restores the
  /// newest backup instead of creating an empty library. When
  /// [createIfMissing] is true and neither exists, creates a new writable
  /// PureWriter v27 library (and an empty `Backups` folder).
  Future<LibraryLocation> openLibrary(
    String selectedPath, {
    bool createIfMissing = false,
  }) async {
    await close();
    final resolved = resolvePureWriterLibrary(selectedPath);
    var isNewLibrary = !resolved.room.existsSync();
    final latestBackup = _backups.findLatestBackup(resolved.root);
    if (isNewLibrary) {
      if (latestBackup != null) {
        await resolved.app.create(recursive: true);
        await _backups.restoreRoomDb(
          pwb: latestBackup,
          destinationRoomDb: resolved.room,
        );
        isNewLibrary = false;
      } else if (!createIfMissing) {
        throw ArgumentError(
          'Expected App/Room.db (with optional Backups/) in $selectedPath',
        );
      } else {
        await resolved.app.create(recursive: true);
        await Directory(
          path.join(resolved.root.path, 'Backups'),
        ).create(recursive: true);
      }
    } else if (latestBackup != null &&
        _looksLikeEmptyStubLibrary(resolved.room, latestBackup) &&
        await _roomHasNoArticleContent(resolved.room)) {
      // Android PureWriter often keeps the live corpus in Backups while App/
      // only has a tiny placeholder Room.db — never keep an empty stub.
      // Skip when the stub already has article text (Zephyr may have written).
      await _backups.restoreRoomDb(
        pwb: latestBackup,
        destinationRoomDb: resolved.room,
      );
      isNewLibrary = false;
    }
    await _acquireLock(resolved.app);
    try {
      // Keep the factory local to this service. Assigning FFI as sqflite's
      // global default causes a warning and can affect other plugins.
      final options = isNewLibrary
          ? OpenDatabaseOptions(version: 27, onCreate: _createSchema)
          // Open existing PureWriter databases as-is; do not bump user_version.
          : OpenDatabaseOptions();
      _database = await _libraryDatabaseFactory.openDatabase(
        resolved.room.path,
        options: options,
      );
      _database = await _ensureCompleteSchema(
        database: _database!,
        room: resolved.room,
        createIfMissing: createIfMissing || isNewLibrary,
      );
      await _ensureZephyrTables(_database!);
      _location = LibraryLocation(
        rootPath: resolved.root.path,
        schema: await _readSchema(_database!),
      );
      return _location!;
    } on Object {
      await close();
      rethrow;
    }
  }

  /// Absolute path to the open library's `App/Room.db`.
  File get roomDbFile {
    final root = location?.rootPath;
    if (root == null) {
      throw StateError('No PureWriter library is open.');
    }
    return resolvePureWriterLibrary(root).room;
  }

  PureWriterBackup get backups => _backups;

  /// Lightweight on-disk snapshot of [roomDbFile] for `.pwb` packing.
  ///
  /// Checkpoint merges WAL into the main file, then copy runs in a background
  /// isolate (avoids `VACUUM INTO` on the UI path).
  Future<File> snapshotRoomDbToTemp() async {
    final db = database;
    final sourcePath = roomDbFile.path;
    final tempDir = await Directory.systemTemp.createTemp('zephyr-room-snap-');
    final destPath = path.join(tempDir.path, 'Room.db');
    try {
      await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    } on Object {
      try {
        await db.execute('PRAGMA wal_checkpoint(FULL)');
      } on Object {
        // Non-WAL journals ignore checkpoint.
      }
    }
    await Isolate.run(() {
      File(sourcePath).copySync(destPath);
    });
    return File(destPath);
  }

  /// Opens an external SQLite file read-only (e.g. extracted backup).
  Future<Database> openReadOnlyDatabase(File file) =>
      _libraryDatabaseFactory.openDatabase(
        file.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

  Future<void> _ensureZephyrTables(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS ZephyrDraft ('
      'article_id TEXT NOT NULL PRIMARY KEY, '
      'content TEXT NOT NULL, '
      'title TEXT NOT NULL, '
      'updated_at INTEGER NOT NULL'
      ')',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS ZephyrMeta ('
      'key TEXT NOT NULL PRIMARY KEY, '
      'value TEXT NOT NULL'
      ')',
    );
  }

  void ensureWritable() {
    if (!writesAllowed) {
      throw StateError('PureWriter schema mismatch: the library is read-only.');
    }
  }

  Future<Map<String, double>> readScrolls() async {
    final file = File(path.join(_app.path, 'Scrolls.json'));
    if (!await file.exists()) return const {};
    final body = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return body.map(
      (id, value) => MapEntry(
        id,
        ((value as Map<String, dynamic>)['s'] as num).toDouble(),
      ),
    );
  }

  Future<void> writeScroll(String articleId, double offset) async {
    ensureWritable();
    final old = await readScrolls();
    final now = DateTime.now().millisecondsSinceEpoch;
    await File(path.join(_app.path, 'Scrolls.json')).writeAsString(
      jsonEncode({
        for (final e in old.entries) e.key: {'s': e.value, 't': now},
        articleId: {'s': offset, 't': now},
      }),
      flush: true,
    );
  }

  Directory get _app {
    final root = Directory(_location!.rootPath);
    return findChildDirectory(root, 'app') ??
        Directory(path.join(root.path, 'App'));
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _location = null;
    if (db != null) await db.close();
    final lock = _lock;
    _lock = null;
    if (lock != null) {
      await lock.unlock();
      await lock.close();
    }
  }

  Future<void> _acquireLock(Directory app) async {
    final lockFile = File(path.join(app.path, '.zephyr-lock'));
    // Mobile / shared storage often rejects POSIX flock; keep a soft marker.
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await lockFile.writeAsString('zephyr:$pid', flush: true);
      } on Object {
        // Best-effort only; still open the library for reading/writing.
      }
      return;
    }
    final lock = await lockFile.open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      await lock.setPosition(0);
      await lock.truncate(0);
      await lock.writeString('zephyr:$pid');
      await lock.flush();
      _lock = lock;
    } on FileSystemException catch (error) {
      await lock.close();
      if (error.osError?.errorCode == 35) {
        throw LibraryInUseException(app.parent.path);
      }
      rethrow;
    }
  }

  Future<SchemaStatus> _readSchema(Database db) async {
    final version = await db.rawQuery('PRAGMA user_version');
    List<Map<String, Object?>> master;
    try {
      master = await db.query(
        'room_master_table',
        columns: ['identity_hash'],
        where: 'id = 42',
        limit: 1,
      );
    } on DatabaseException {
      master = const [];
    }
    final userVersion = version.single.values.single as int;
    final hash = master.isEmpty
        ? ''
        : master.single['identity_hash']! as String;
    return SchemaStatus(
      userVersion: userVersion,
      identityHash: hash,
      writesAllowed: userVersion == 27 && hash == identityHash,
    );
  }

  Future<void> _createSchema(Database db, int _) async {
    // Native Android/iOS sqflite accepts only one statement per execute;
    // sqflite_ffi on desktop may run multi-statement scripts, which hid this.
    final batch = db.batch();
    for (final statement in _schemaStatements) {
      batch.execute(statement);
    }
    batch.execute(
      'CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT)',
    );
    await batch.commit(noResult: true);
    await db.insert('room_master_table', {
      'id': 42,
      'identity_hash': identityHash,
    });
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final row in [
      (defaultFolderId, 'Default', 0),
      (trashFolderId, 'Trash', 1),
    ]) {
      await db.insert('Folder', {
        'id': row.$1,
        'name': row.$2,
        'createdTime': now,
        'rank': row.$3,
        'deleted': 0,
        'deletedTime': 0,
        'updateTime': now,
        'rankUpdateTime': now,
        'autoChapter': 0,
        'autoChapterUpdateTime': 0,
        'autoChapterResetForCategory': 0,
        'autoChapterResetForCategoryUpdateTime': 0,
        'autoChapterReplaceBadPrefix': 0,
        'autoChapterReplaceBadPrefixUpdateTime': 0,
        'tagsUpdateTime': now,
        'rankModeUpdateTime': 0,
      });
    }
  }

  /// Recreates a Zephyr-owned library that only got a partial schema (e.g. the
  /// multi-statement `onCreate` bug on Android, which left Folder but no Article).
  Future<Database> _ensureCompleteSchema({
    required Database database,
    required File room,
    required bool createIfMissing,
  }) async {
    if (await _hasTable(database, 'Article')) {
      return database;
    }
    final schema = await _readSchema(database);
    // Only wipe DBs we created (v27 fingerprint) or empty placeholders we are
    // allowed to replace — never a foreign PureWriter corpus missing Article.
    final canRepair = schema.identityHash == identityHash ||
        (createIfMissing && !await _hasTable(database, 'Folder'));
    if (!canRepair) {
      await database.close();
      throw StateError(
        'PureWriter library is missing the Article table: ${room.path}',
      );
    }
    await database.close();
    await _deleteSqliteFiles(room);
    return _libraryDatabaseFactory.openDatabase(
      room.path,
      options: OpenDatabaseOptions(version: 27, onCreate: _createSchema),
    );
  }
}

Future<bool> _hasTable(Database db, String name) async {
  final rows = await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
    [name],
  );
  return rows.isNotEmpty;
}

Future<void> _deleteSqliteFiles(File room) async {
  for (final path in [
    room.path,
    '${room.path}-journal',
    '${room.path}-wal',
    '${room.path}-shm',
  ]) {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// True when [room] is a tiny placeholder compared to a much larger `.pwb`.
bool _looksLikeEmptyStubLibrary(File room, File latestBackup) {
  final roomSize = room.existsSync() ? room.lengthSync() : 0;
  final backupSize = latestBackup.lengthSync();
  // Fresh Zephyr stubs are ~100KB; real PureWriter libraries / backups are
  // hundreds of KB to multiple MB once they contain books.
  return roomSize > 0 && roomSize < 200 * 1024 && backupSize > roomSize * 3;
}

/// Opens [room] read-only and reports whether any article has non-empty content.
Future<bool> _roomHasNoArticleContent(File room) async {
  if (!room.existsSync()) return true;
  Database? db;
  try {
    db = await _libraryDatabaseFactory.openDatabase(
      room.path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    if (!await _hasTable(db, 'Article')) return true;
    final rows = await db.rawQuery(
      "SELECT 1 FROM Article WHERE deleted = 0 AND length(trim(content)) > 0 "
      'LIMIT 1',
    );
    return rows.isEmpty;
  } on Object {
    // Unreadable stub — treat as empty so backup restore can proceed.
    return true;
  } finally {
    await db?.close();
  }
}

/// Platform database factory: native sqflite on mobile, FFI on desktop.
DatabaseFactory get _libraryDatabaseFactory {
  if (Platform.isAndroid || Platform.isIOS) {
    return databaseFactory;
  }
  sqfliteFfiInit();
  return databaseFactoryFfi;
}

/// Resolved PureWriter on-disk layout for a user-selected path.
class ResolvedPureWriterLibrary {
  const ResolvedPureWriterLibrary({
    required this.root,
    required this.app,
    required this.room,
  });

  final Directory root;
  final Directory app;
  final File room;
}

/// Maps a picked folder to `{root}/App/Room.db`, tolerating `App` selection and
/// case differences used on Android (`App`, `Backups`).
ResolvedPureWriterLibrary resolvePureWriterLibrary(String selectedPath) {
  final selected = Directory(selectedPath);

  if (_isNamed(selected, 'app')) {
    final room = findChildFile(selected, 'room.db');
    if (room != null) {
      return ResolvedPureWriterLibrary(
        root: selected.parent,
        app: selected,
        room: room,
      );
    }
  }

  final appUnderSelected = findChildDirectory(selected, 'app');
  if (appUnderSelected != null) {
    final room = findChildFile(appUnderSelected, 'room.db') ??
        File(path.join(appUnderSelected.path, 'Room.db'));
    return ResolvedPureWriterLibrary(
      root: selected,
      app: appUnderSelected,
      room: room,
    );
  }

  final roomInSelected = findChildFile(selected, 'room.db');
  if (roomInSelected != null) {
    return ResolvedPureWriterLibrary(
      root: selected.parent,
      app: selected,
      room: roomInSelected,
    );
  }

  final app = Directory(path.join(selected.path, 'App'));
  return ResolvedPureWriterLibrary(
    root: selected,
    app: app,
    room: File(path.join(app.path, 'Room.db')),
  );
}

Directory? findChildDirectory(Directory parent, String name) {
  if (!parent.existsSync()) return null;
  for (final entity in parent.listSync(followLinks: false)) {
    if (entity is Directory && _isNamed(entity, name)) {
      return entity;
    }
  }
  return null;
}

File? findChildFile(Directory parent, String name) {
  if (!parent.existsSync()) return null;
  for (final entity in parent.listSync(followLinks: false)) {
    if (entity is File && _isNamed(entity, name)) {
      return entity;
    }
  }
  return null;
}

bool _isNamed(FileSystemEntity entity, String name) =>
    path.basename(entity.path).toLowerCase() == name.toLowerCase();

const _schemaStatements = <String>[
  'CREATE TABLE Folder (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, createdTime INTEGER NOT NULL, description TEXT, rank INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, selectedArticleId TEXT, selectedArticleId1 TEXT, selectedOutlineId TEXT, extension TEXT, updateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, autoChapter INTEGER NOT NULL, autoChapterUpdateTime INTEGER NOT NULL, autoChapterResetForCategory INTEGER NOT NULL, autoChapterResetForCategoryUpdateTime INTEGER NOT NULL, autoChapterReplaceBadPrefix INTEGER NOT NULL, autoChapterReplaceBadPrefixUpdateTime INTEGER NOT NULL, tags TEXT, tagsUpdateTime INTEGER NOT NULL, rankMode TEXT, rankModeUpdateTime INTEGER NOT NULL DEFAULT 0)',
  'CREATE TABLE Category (id TEXT NOT NULL PRIMARY KEY, folderId TEXT NOT NULL, name TEXT NOT NULL, createdTime INTEGER NOT NULL, collapsed INTEGER NOT NULL, rank INTEGER NOT NULL, description TEXT, rankUpdateTime INTEGER NOT NULL, folderIdUpdateTime INTEGER NOT NULL, updateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, orderKey TEXT, structureUpdateTime INTEGER NOT NULL DEFAULT 0)',
  'CREATE INDEX index_Category_folderId ON Category (folderId)',
  'CREATE TABLE Article (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, summary TEXT, count INTEGER, extension TEXT NOT NULL, preview INTEGER NOT NULL, preview1 INTEGER NOT NULL, updateTime INTEGER NOT NULL, createTime INTEGER NOT NULL, folderId TEXT NOT NULL, categoryId TEXT, editorId INTEGER NOT NULL, rank INTEGER NOT NULL, titleUpdateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, folderIdUpdateTime INTEGER NOT NULL, categoryIdUpdateTime INTEGER NOT NULL, extensionUpdateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, autoChapter INTEGER NOT NULL, autoChapterUpdateTime INTEGER NOT NULL, orderKey TEXT, structureUpdateTime INTEGER NOT NULL DEFAULT 0)',
  'CREATE INDEX index_Article_folderId ON Article (folderId)',
  'CREATE TABLE Setting (`key` TEXT NOT NULL PRIMARY KEY, `value` TEXT NOT NULL, updateTime INTEGER NOT NULL DEFAULT 0)',
  'CREATE TABLE Daily (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, year INTEGER NOT NULL, month INTEGER NOT NULL, day INTEGER NOT NULL, articleId TEXT NOT NULL, articleTitle TEXT NOT NULL, folderId TEXT NOT NULL, folderTitle TEXT NOT NULL, inputtingDuration INTEGER NOT NULL, foregroundDuration INTEGER NOT NULL, wordCount INTEGER NOT NULL, wordCountMode TEXT NOT NULL, countFullWord INTEGER NOT NULL, extras TEXT, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL)',
  'CREATE TABLE History (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, createTime INTEGER NOT NULL, article_id TEXT, article_title TEXT, article_content TEXT, article_summary TEXT, article_count INTEGER, article_extension TEXT, article_preview INTEGER, article_preview1 INTEGER, article_updateTime INTEGER, article_createTime INTEGER, article_folderId TEXT, article_categoryId TEXT, article_editorId INTEGER, article_rank INTEGER, article_titleUpdateTime INTEGER, article_rankUpdateTime INTEGER, article_folderIdUpdateTime INTEGER, article_categoryIdUpdateTime INTEGER, article_extensionUpdateTime INTEGER, article_deleted INTEGER, article_deletedTime INTEGER, article_autoChapter INTEGER, article_autoChapterUpdateTime INTEGER, article_orderKey TEXT, article_structureUpdateTime INTEGER DEFAULT 0)',
  'CREATE INDEX index_History_article_id ON History (article_id)',
  'CREATE TABLE Shortcut (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL, content TEXT NOT NULL, cursorIndexStart INTEGER NOT NULL, cursorIndexEnd INTEGER NOT NULL, rank INTEGER NOT NULL, deletable INTEGER NOT NULL, folderId TEXT, updateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, lineId INTEGER NOT NULL DEFAULT 0)',
  'CREATE TABLE License (id TEXT NOT NULL, deviceId TEXT NOT NULL, PRIMARY KEY(id))',
  'CREATE TABLE UserMessage (id TEXT NOT NULL PRIMARY KEY, fromUserId TEXT NOT NULL, type TEXT NOT NULL, content BLOB NOT NULL, createdTime INTEGER NOT NULL, shownState INTEGER NOT NULL, extra TEXT, updateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL)',
  // Native Android/iOS sqflite already creates this table before onCreate;
  // IF NOT EXISTS keeps desktop FFI and mobile create paths aligned.
  'CREATE TABLE IF NOT EXISTS android_metadata (locale TEXT)',
];
