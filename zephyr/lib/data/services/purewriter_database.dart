import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the PureWriter-compatible `App/Room.db` owned by this Zephyr install.
class PureWriterDatabase {
  static const defaultFolderId = 'Default';
  static const trashFolderId = 'PW_Trash';
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final root = await getApplicationSupportDirectory();
    final appDirectory = Directory(path.join(root.path, 'App'));
    await appDirectory.create(recursive: true);
    final db = await openDatabase(
      path.join(appDirectory.path, 'Room.db'),
      version: 27,
      onCreate: (database, _) async {
        await database.execute(_schema);
        await database.execute(
          'CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT)',
        );
        await database.insert('room_master_table', {
          'id': 42,
          'identity_hash': 'af22c7c534a04acc4530d670ac9e43c4',
        });
        await _createSystemFolders(database);
      },
    );
    return db;
  }

  Future<void> _createSystemFolders(Database database) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final folder in [
      (defaultFolderId, 'Default', 0),
      (trashFolderId, 'Trash', 1),
    ]) {
      await database.insert('Folder', {
        'id': folder.$1,
        'name': folder.$2,
        'createdTime': now,
        'rank': folder.$3,
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
''';
