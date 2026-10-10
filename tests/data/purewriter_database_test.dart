import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_backup.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/library_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PackageInfo.setMockInitialValues(
    appName: 'Zephyr',
    packageName: 'com.zephyr.zephyr',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );

  late Directory root;
  late PureWriterDatabase database;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('zephyr-purewriter-test-');
    database = PureWriterDatabase(supportDirectory: () async => root);
    await database.openDefaultLibrary();
  });

  tearDown(() async {
    await database.close();
    await root.delete(recursive: true);
  });

  test('creates a complete v27 library with a writable schema gate', () async {
    expect(database.location?.schema.isKnownV27, isTrue);
    expect(database.writesAllowed, isTrue);
    final tables = await database.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll([
        'Article',
        'Folder',
        'Category',
        'History',
        'Daily',
        'Shortcut',
        'License',
        'UserMessage',
        'ZephyrDraft',
        'ZephyrMeta',
        'Setting',
      ]),
    );
  });

  test('creates App/Room.db when opening an empty folder as a new library', () async {
    final emptyRoot = await Directory.systemTemp.createTemp(
      'zephyr-empty-library-',
    );
    addTearDown(() => emptyRoot.delete(recursive: true));
    final folder = await Directory(
      path.join(emptyRoot.path, 'My Library'),
    ).create();
    final store = PureWriterDatabase(supportDirectory: () async => emptyRoot);
    addTearDown(store.close);

    final repository = PureWriterWritingLibraryRepository(store);
    final location = await repository.openLibrary(folder.path);

    expect(location.rootPath, folder.path);
    expect(location.schema.writesAllowed, isTrue);
    expect(
      File(path.join(folder.path, 'App', 'Room.db')).existsSync(),
      isTrue,
    );
    expect(
      Directory(path.join(folder.path, 'Backups')).existsSync(),
      isTrue,
    );
    final library = await repository.loadLibrary();
    expect(
      library.folders.any((item) => item.id == PureWriterDatabase.defaultFolderId),
      isTrue,
    );
  });

  test('opens an Android-style App + Backups library root', () async {
    final androidRoot = await Directory.systemTemp.createTemp(
      'zephyr-android-library-',
    );
    addTearDown(() => androidRoot.delete(recursive: true));
    final libraryRoot = await Directory(
      path.join(androidRoot.path, 'Documents'),
    ).create();
    final seed = PureWriterDatabase(supportDirectory: () async => androidRoot);
    addTearDown(seed.close);
    await seed.openLibrary(libraryRoot.path, createIfMissing: true);
    await seed.close();

    await Directory(path.join(libraryRoot.path, 'Backups')).create();
    await File(
      path.join(libraryRoot.path, 'Backups', '2026-01-01.pwb'),
    ).writeAsString('backup-placeholder');

    final store = PureWriterDatabase(supportDirectory: () async => androidRoot);
    addTearDown(store.close);
    final location = await store.openLibrary(libraryRoot.path);

    expect(location.rootPath, libraryRoot.path);
    expect(
      File(path.join(libraryRoot.path, 'App', 'Room.db')).existsSync(),
      isTrue,
    );
    expect(
      File(
        path.join(libraryRoot.path, 'Backups', '2026-01-01.pwb'),
      ).existsSync(),
      isTrue,
    );
  });

  test('opens when the App directory itself is selected', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-app-selected-');
    addTearDown(() => root.delete(recursive: true));
    final libraryRoot = await Directory(path.join(root.path, 'Lib')).create();
    final seed = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(seed.close);
    await seed.openLibrary(libraryRoot.path, createIfMissing: true);
    await seed.close();

    final store = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(store.close);
    final appDir = Directory(path.join(libraryRoot.path, 'App'));
    final location = await store.openLibrary(appDir.path);
    expect(location.rootPath, libraryRoot.path);
  });

  test(
    'restores Room.db from the newest Backups/*.pwb when missing',
    () async {
      final root = await Directory.systemTemp.createTemp('zephyr-pwb-restore-');
      addTearDown(() => root.delete(recursive: true));
      final libraryRoot = await Directory(path.join(root.path, 'PW')).create();
      final seed = PureWriterDatabase(supportDirectory: () async => root);
      addTearDown(seed.close);
      await seed.openLibrary(libraryRoot.path, createIfMissing: true);
      final article = await PureWriterWritingLibraryRepository(seed)
          .createArticle(
        folderId: PureWriterDatabase.defaultFolderId,
      );
      await PureWriterWritingLibraryRepository(seed).saveArticle(
        article.copyWith(content: 'From backup'),
      );
      await seed.close();

      final room = File(path.join(libraryRoot.path, 'App', 'Room.db'));
      final backups = Directory(path.join(libraryRoot.path, 'Backups', 'Auto'))
        ..createSync(recursive: true);
      final pwb = File(path.join(backups.path, 'library.pwb'));
      await _packPwb(room: room, pwb: pwb);
      await room.delete();

      final store = PureWriterDatabase(supportDirectory: () async => root);
      addTearDown(store.close);
      await store.openLibrary(libraryRoot.path);
      final reloaded = await PureWriterWritingLibraryRepository(store)
          .getArticle(
        article.id,
      );
      expect(reloaded.content, 'From backup');
    },
  );

  test('resolvePureWriterLibrary maps Android layout paths', () {
    final root = Directory.systemTemp.createTempSync('zephyr-resolve-');
    addTearDown(() => root.deleteSync(recursive: true));
    final library = Directory(path.join(root.path, 'PW'))..createSync();
    final app = Directory(path.join(library.path, 'App'))..createSync();
    File(path.join(app.path, 'Room.db')).writeAsStringSync('');
    Directory(path.join(library.path, 'Backups')).createSync();

    final fromRoot = resolvePureWriterLibrary(library.path);
    expect(fromRoot.root.path, library.path);
    expect(fromRoot.app.path, app.path);
    expect(path.basename(fromRoot.room.path), 'Room.db');

    final fromApp = resolvePureWriterLibrary(app.path);
    expect(fromApp.root.path, library.path);
    expect(fromApp.room.path, fromRoot.room.path);
  });

  test('refuses to invent a library when createIfMissing is false', () async {
    final emptyRoot = await Directory.systemTemp.createTemp(
      'zephyr-missing-library-',
    );
    addTearDown(() => emptyRoot.delete(recursive: true));
    final store = PureWriterDatabase(supportDirectory: () async => emptyRoot);
    addTearDown(store.close);

    expect(
      () => store.openLibrary(emptyRoot.path),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('creates library over Room.db that only has android_metadata', () async {
    // Android sqflite inserts android_metadata before onCreate. A failed
    // schema create used to leave that stub; opening the folder again must
    // still build a writable library when createIfMissing is true.
    final root = await Directory.systemTemp.createTemp(
      'zephyr-android-metadata-stub-',
    );
    addTearDown(() => root.delete(recursive: true));
    final libraryRoot = await Directory(path.join(root.path, 'Lib')).create();
    final app = await Directory(path.join(libraryRoot.path, 'App')).create();
    final room = File(path.join(app.path, 'Room.db'));

    sqfliteFfiInit();
    final stub = await databaseFactoryFfi.openDatabase(room.path);
    await stub.execute('CREATE TABLE android_metadata (locale TEXT)');
    await stub.close();

    final store = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(store.close);
    final location = await store.openLibrary(
      libraryRoot.path,
      createIfMissing: true,
    );
    expect(location.schema.writesAllowed, isTrue);
    final tables = await store.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(tables.map((row) => row['name']), contains('Article'));
  });

  test('repairs a Zephyr library that only received a partial schema', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-partial-schema-');
    addTearDown(() => root.delete(recursive: true));
    final libraryRoot = await Directory(path.join(root.path, 'Lib')).create();
    final app = await Directory(path.join(libraryRoot.path, 'App')).create();
    final room = File(path.join(app.path, 'Room.db'));

    // Simulate Android sqflite running only the first CREATE from a multi-
    // statement script, then still writing the Room identity fingerprint.
    final seed = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(seed.close);
    await seed.openLibrary(libraryRoot.path, createIfMissing: true);
    await seed.database.execute('DROP TABLE IF EXISTS Article');
    await seed.database.execute('DROP TABLE IF EXISTS Category');
    await seed.database.execute('DROP TABLE IF EXISTS History');
    await seed.close();

    expect(room.existsSync(), isTrue);

    final store = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(store.close);
    final location = await store.openLibrary(libraryRoot.path);
    expect(location.schema.writesAllowed, isTrue);
    final tables = await store.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(tables.map((row) => row['name']), contains('Article'));
    final library = await PureWriterWritingLibraryRepository(store).loadLibrary();
    expect(
      library.folders.any((item) => item.id == PureWriterDatabase.defaultFolderId),
      isTrue,
    );
  });

  test('inserts, renames, moves, reorders, and deletes volumes/chapters', () async {
    final repository = PureWriterWritingLibraryRepository(database);
    final first = await repository.createCategory(
      folderId: PureWriterDatabase.defaultFolderId,
      name: 'Volume 1',
    );
    final second = await repository.createCategory(
      folderId: PureWriterDatabase.defaultFolderId,
      name: 'Volume 2',
      afterCategoryId: first.id,
    );
    final chapter = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
      categoryId: first.id,
    );
    final below = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
      categoryId: first.id,
      afterArticleId: chapter.id,
    );

    await repository.renameCategory(categoryId: first.id, name: 'Renamed volume');
    await repository.renameArticle(articleId: chapter.id, title: 'Renamed chapter');
    await repository.moveArticleToCategory(
      articleId: below.id,
      categoryId: second.id,
    );
    await repository.reorderCategories(
      folderId: PureWriterDatabase.defaultFolderId,
      orderedIds: [second.id, first.id],
    );

    var library = await repository.loadLibrary();
    expect(
      library.categories.map((item) => item.id).toList(),
      [second.id, first.id],
    );
    expect(
      library.categories.singleWhere((item) => item.id == first.id).name,
      'Renamed volume',
    );
    expect(
      (await repository.getArticle(chapter.id)).title,
      'Renamed chapter',
    );
    expect(
      library.articles.singleWhere((item) => item.id == below.id).categoryId,
      second.id,
    );

    await repository.deleteCategory(categoryId: first.id, deleteArticles: false);
    library = await repository.loadLibrary();
    expect(library.categories.any((item) => item.id == first.id), isFalse);
    expect(
      library.articles.singleWhere((item) => item.id == chapter.id).categoryId,
      isNull,
    );

    await repository.deleteCategory(categoryId: second.id, deleteArticles: true);
    library = await repository.loadLibrary();
    expect(library.categories.any((item) => item.id == second.id), isFalse);
    expect(
      library.articles.singleWhere((item) => item.id == below.id).folderId,
      PureWriterDatabase.trashFolderId,
    );
  });

  test('saves content without overwriting unrelated article fields and records history', () async {
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );
    await repository.saveArticle(article.copyWith(content: 'First draft.'));
    final reloaded = await repository.getArticle(article.id);
    final history = await repository.listHistory(article.id);

    expect(reloaded.content, 'First draft.');
    expect(reloaded.createdAt, article.createdAt);
    expect(reloaded.wordCount, 'First draft.'.runes.length);
    final summary = (await repository.loadLibrary()).articles.singleWhere(
      (item) => item.id == article.id,
    );
    expect(summary.createdAt, article.createdAt);
    expect(summary.updatedAt, reloaded.updatedAt);
    expect(summary.wordCount, reloaded.wordCount);
    expect(history, hasLength(1));
    expect(history.single.content, isEmpty);
    final raw = await database.database.query(
      'Article',
      columns: ['editorId', 'preview', 'preview1'],
      where: 'id = ?',
      whereArgs: [article.id],
    );
    expect(raw.single, {'editorId': 0, 'preview': 0, 'preview1': 0});
  });

  test('creates ZephyrDraft table and round-trips crash drafts', () async {
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );
    await repository.upsertDraft(
      ArticleDraft(
        articleId: article.id,
        content: 'Draft body',
        title: 'Draft title',
        updatedAt: DateTime.utc(2026, 4, 1),
      ),
    );
    final draft = await repository.getDraft(article.id);
    expect(draft?.content, 'Draft body');
    expect(draft?.title, 'Draft title');
    await repository.clearDraft(article.id);
    expect(await repository.getDraft(article.id), isNull);
  });

  test('createBackup writes a .pwb that listBackups can see', () async {
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );
    await repository.saveArticle(article.copyWith(content: 'Backup me'));
    final entry = await repository.createBackup(kind: BackupKind.manual);
    expect(entry.kind, BackupKind.manual);
    expect(File(entry.path).existsSync(), isTrue);
    expect(entry.fileName, contains('books-'));
    expect(entry.fileName, contains('articles.pwb'));
    expect(entry.fileName, contains('0.1.0'));
    final listed = await repository.listBackups();
    expect(listed.any((item) => item.path == entry.path), isTrue);
  });

  test('restoreHistory rewrites article content from History', () async {
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );
    await repository.saveArticle(article.copyWith(content: 'v1'));
    await repository.saveArticle(
      (await repository.getArticle(article.id)).copyWith(content: 'v2'),
    );
    final history = await repository.listHistory(article.id);
    expect(history, isNotEmpty);
    final older = history.last;
    await repository.restoreHistory(
      articleId: article.id,
      createdAt: older.createdAt,
    );
    final restored = await repository.getArticle(article.id);
    expect(restored.content, older.content);
  });
}

Future<void> _packPwb({required File room, required File pwb}) =>
    packRoomDbToPwb(roomDbPath: room.path, pwbPath: pwb.path);
