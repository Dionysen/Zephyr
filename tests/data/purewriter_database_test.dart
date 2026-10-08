import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';

void main() {
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

  test('restores Room.db from the newest Backups/*.pwb when missing', () async {
    final root = await Directory.systemTemp.createTemp('zephyr-pwb-restore-');
    addTearDown(() => root.delete(recursive: true));
    final libraryRoot = await Directory(path.join(root.path, 'PW')).create();
    final seed = PureWriterDatabase(supportDirectory: () async => root);
    addTearDown(seed.close);
    await seed.openLibrary(libraryRoot.path, createIfMissing: true);
    final article = await PureWriterWritingLibraryRepository(seed).createArticle(
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
    final reloaded = await PureWriterWritingLibraryRepository(store).getArticle(
      article.id,
    );
    expect(reloaded.content, 'From backup');
  });

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
}

Future<void> _packPwb({required File room, required File pwb}) async {
  final staging = await Directory.systemTemp.createTemp('zephyr-pack-pwb-');
  try {
    final dbName = 'PureWriterBackup-test.db';
    await room.copy(path.join(staging.path, dbName));
    final packed = await Process.run('bsdtar', [
      '--format',
      '7zip',
      '-cf',
      pwb.path,
      '-C',
      staging.path,
      dbName,
    ]);
    expect(packed.exitCode, 0, reason: '${packed.stderr}');
  } finally {
    await staging.delete(recursive: true);
  }
}
