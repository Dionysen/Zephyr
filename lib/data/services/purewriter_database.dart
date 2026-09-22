import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models/purewriter_models.dart';

/// Owns one PureWriter library connection and its cross-process `.zephyr-lock`.
class PureWriterDatabase {
  PureWriterDatabase({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;
  static const defaultFolderId = 'Default';
  static const trashFolderId = 'PW_Trash';
  static const identityHash = 'af22c7c534a04acc4530d670ac9e43c4';
  final Future<Directory> Function() _supportDirectory;
  Database? _database;
  RandomAccessFile? _lock;
  LibraryLocation? _location;
  LibraryLocation? get location => _location;
  Database get database =>
      _database ?? (throw StateError('No PureWriter library is open.'));
  bool get writesAllowed => _location?.schema.writesAllowed ?? false;

  Future<LibraryLocation> openDefaultLibrary() async =>
      openLibrary((await _supportDirectory()).path, createIfMissing: true);

  /// Opens a library root containing `App/Room.db`; an `App` directory is also accepted.
  Future<LibraryLocation> openLibrary(
    String selectedPath, {
    bool createIfMissing = false,
  }) async {
    await close();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final selected = Directory(selectedPath);
    final root = path.basename(selected.path).toLowerCase() == 'app'
        ? selected.parent
        : selected;
    final app = Directory(path.join(root.path, 'App'));
    final room = File(path.join(app.path, 'Room.db'));
    if (!room.existsSync()) {
      if (!createIfMissing) {
        throw ArgumentError('Expected App/Room.db in $selectedPath');
      }
      await app.create(recursive: true);
    }
    await _acquireLock(app);
    try {
      _database = await openDatabase(
        room.path,
        version: 27,
        onCreate: createIfMissing ? _createSchema : null,
      );
      _location = LibraryLocation(
        rootPath: root.path,
        schema: await _readSchema(_database!),
      );
      return _location!;
    } on Object {
      await close();
      rethrow;
    }
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

  Directory get _app => Directory(path.join(_location!.rootPath, 'App'));
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
    final lock = await File(path.join(app.path, '.zephyr-lock'))
        .open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.exclusive);
      await lock.setPosition(0);
      await lock.truncate(0);
      await lock.writeString('zephyr:$pid');
      await lock.flush();
      _lock = lock;
    } on Object {
      await lock.close();
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
    await db.execute(_schema);
    await db.execute(
      'CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT)',
    );
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
}

const _schema = '''
CREATE TABLE Folder (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, createdTime INTEGER NOT NULL, description TEXT, rank INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, selectedArticleId TEXT, selectedArticleId1 TEXT, selectedOutlineId TEXT, extension TEXT, updateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, autoChapter INTEGER NOT NULL, autoChapterUpdateTime INTEGER NOT NULL, autoChapterResetForCategory INTEGER NOT NULL, autoChapterResetForCategoryUpdateTime INTEGER NOT NULL, autoChapterReplaceBadPrefix INTEGER NOT NULL, autoChapterReplaceBadPrefixUpdateTime INTEGER NOT NULL, tags TEXT, tagsUpdateTime INTEGER NOT NULL, rankMode TEXT, rankModeUpdateTime INTEGER NOT NULL DEFAULT 0);
CREATE TABLE Category (id TEXT NOT NULL PRIMARY KEY, folderId TEXT NOT NULL, name TEXT NOT NULL, createdTime INTEGER NOT NULL, collapsed INTEGER NOT NULL, rank INTEGER NOT NULL, description TEXT, rankUpdateTime INTEGER NOT NULL, folderIdUpdateTime INTEGER NOT NULL, updateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, orderKey TEXT, structureUpdateTime INTEGER NOT NULL DEFAULT 0);
CREATE INDEX index_Category_folderId ON Category (folderId);
CREATE TABLE Article (id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, content TEXT NOT NULL, summary TEXT, count INTEGER, extension TEXT NOT NULL, preview INTEGER NOT NULL, preview1 INTEGER NOT NULL, updateTime INTEGER NOT NULL, createTime INTEGER NOT NULL, folderId TEXT NOT NULL, categoryId TEXT, editorId INTEGER NOT NULL, rank INTEGER NOT NULL, titleUpdateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, folderIdUpdateTime INTEGER NOT NULL, categoryIdUpdateTime INTEGER NOT NULL, extensionUpdateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, autoChapter INTEGER NOT NULL, autoChapterUpdateTime INTEGER NOT NULL, orderKey TEXT, structureUpdateTime INTEGER NOT NULL DEFAULT 0);
CREATE INDEX index_Article_folderId ON Article (folderId);
CREATE TABLE Setting (`key` TEXT NOT NULL PRIMARY KEY, `value` TEXT NOT NULL, updateTime INTEGER NOT NULL DEFAULT 0);
CREATE TABLE Daily (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, year INTEGER NOT NULL, month INTEGER NOT NULL, day INTEGER NOT NULL, articleId TEXT NOT NULL, articleTitle TEXT NOT NULL, folderId TEXT NOT NULL, folderTitle TEXT NOT NULL, inputtingDuration INTEGER NOT NULL, foregroundDuration INTEGER NOT NULL, wordCount INTEGER NOT NULL, wordCountMode TEXT NOT NULL, countFullWord INTEGER NOT NULL, extras TEXT, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL);
CREATE TABLE History (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, createTime INTEGER NOT NULL, article_id TEXT, article_title TEXT, article_content TEXT, article_summary TEXT, article_count INTEGER, article_extension TEXT, article_preview INTEGER, article_preview1 INTEGER, article_updateTime INTEGER, article_createTime INTEGER, article_folderId TEXT, article_categoryId TEXT, article_editorId INTEGER, article_rank INTEGER, article_titleUpdateTime INTEGER, article_rankUpdateTime INTEGER, article_folderIdUpdateTime INTEGER, article_categoryIdUpdateTime INTEGER, article_extensionUpdateTime INTEGER, article_deleted INTEGER, article_deletedTime INTEGER, article_autoChapter INTEGER, article_autoChapterUpdateTime INTEGER, article_orderKey TEXT, article_structureUpdateTime INTEGER DEFAULT 0);
CREATE INDEX index_History_article_id ON History (article_id);
CREATE TABLE Shortcut (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL, content TEXT NOT NULL, cursorIndexStart INTEGER NOT NULL, cursorIndexEnd INTEGER NOT NULL, rank INTEGER NOT NULL, deletable INTEGER NOT NULL, folderId TEXT, updateTime INTEGER NOT NULL, rankUpdateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL, lineId INTEGER NOT NULL DEFAULT 0);
CREATE TABLE License (id TEXT NOT NULL, deviceId TEXT NOT NULL, PRIMARY KEY(id));
CREATE TABLE UserMessage (id TEXT NOT NULL PRIMARY KEY, fromUserId TEXT NOT NULL, type TEXT NOT NULL, content BLOB NOT NULL, createdTime INTEGER NOT NULL, shownState INTEGER NOT NULL, extra TEXT, updateTime INTEGER NOT NULL, deleted INTEGER NOT NULL, deletedTime INTEGER NOT NULL);
CREATE TABLE android_metadata (locale TEXT);
''';
