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
    final library = await repository.loadLibrary();
    expect(
      library.folders.any((item) => item.id == PureWriterDatabase.defaultFolderId),
      isTrue,
    );
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
