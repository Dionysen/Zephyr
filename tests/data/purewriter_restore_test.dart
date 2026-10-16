import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/library_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('article text longer than one read chunk roundtrips', () async {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Zephyr',
      packageName: 'zephyr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final directory = await Directory.systemTemp.createTemp('zephyr-chunk-');
    final database = PureWriterDatabase(
      supportDirectory: () async => directory,
    );
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    await database.openDefaultLibrary();
    final repository = PureWriterWritingLibraryRepository(database);
    final article = await repository.createArticle(
      folderId: PureWriterDatabase.defaultFolderId,
    );
    final content = '${'a' * 65535}测end';
    await repository.saveArticle(article.copyWith(content: content));

    expect((await repository.getArticle(article.id)).content, content);
  });

  test(
    'overwrite restore returns article content to the selected snapshot',
    () async {
      // ignore: invalid_use_of_visible_for_testing_member
      PackageInfo.setMockInitialValues(
        appName: 'Zephyr',
        packageName: 'zephyr',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-restore-',
      );
      final database = PureWriterDatabase(
        supportDirectory: () async => directory,
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      await database.openDefaultLibrary();
      final repository = PureWriterWritingLibraryRepository(database);
      final article = await repository.createArticle(
        folderId: PureWriterDatabase.defaultFolderId,
      );
      await repository.saveArticle(article.copyWith(content: 'snapshot text'));
      final backup = await repository.createBackup(kind: BackupKind.manual);
      final snapshot = await File(backup.path)
          .copy('${directory.path}/snapshot.pwb');

      await repository.saveArticle(
        (await repository.getArticle(article.id))
            .copyWith(content: 'later edit'),
      );
      expect((await repository.getArticle(article.id)).content, 'later edit');
      await repository.restoreBackup(
        entry: BackupEntry(
          path: snapshot.path,
          fileName: snapshot.uri.pathSegments.last,
          modified: backup.modified,
          sizeBytes: backup.sizeBytes,
          kind: BackupKind.manual,
        ),
        mode: RestoreMode.overwrite,
      );

      expect(
        (await repository.getArticle(article.id)).content,
        'snapshot text',
      );
      expect((await repository.listBackups()).isNotEmpty, isTrue);
    },
  );

  test(
    'merge restore does not bulk-read article content from backup',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'Zephyr',
        packageName: 'zephyr',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-merge-huge-',
      );
      final database = PureWriterDatabase(
        supportDirectory: () async => directory,
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      await database.openDefaultLibrary();
      final repository = PureWriterWritingLibraryRepository(database);
      final article = await repository.createArticle(
        folderId: PureWriterDatabase.defaultFolderId,
      );
      final hugeBody = List.filled(3 * 1024 * 1024, 'x').join();
      await repository.saveArticle(article.copyWith(content: hugeBody));
      final backup = await repository.createBackup(kind: BackupKind.manual);

      await repository.restoreBackup(
        entry: BackupEntry(
          path: backup.path,
          fileName: backup.fileName,
          modified: backup.modified,
          sizeBytes: backup.sizeBytes,
          kind: BackupKind.manual,
        ),
        mode: RestoreMode.merge,
      );

      expect((await repository.getArticle(article.id)).content, hugeBody);
      expect((await repository.loadLibrary()).articles, isNotEmpty);
    },
  );

  test(
    'merge restore does not bulk-read huge article content from local library',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'Zephyr',
        packageName: 'zephyr',
        version: '0.1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-merge-local-huge-',
      );
      final database = PureWriterDatabase(
        supportDirectory: () async => directory,
      );
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      await database.openDefaultLibrary();
      final repository = PureWriterWritingLibraryRepository(database);
      final article = await repository.createArticle(
        folderId: PureWriterDatabase.defaultFolderId,
      );
      await repository.saveArticle(article.copyWith(content: 'remote small'));
      final rows = await database.database.query(
        'Article',
        columns: ['updateTime'],
        where: 'id = ?',
        whereArgs: [article.id],
      );
      final remoteTime = rows.single['updateTime']! as int;
      final backup = await repository.createBackup(kind: BackupKind.manual);
      final hugeBody = List.filled(3 * 1024 * 1024, 'y').join();
      await repository.saveArticle(article.copyWith(content: hugeBody));
      await database.database.update(
        'Article',
        {'updateTime': remoteTime - 1},
        where: 'id = ?',
        whereArgs: [article.id],
      );

      await repository.restoreBackup(
        entry: BackupEntry(
          path: backup.path,
          fileName: backup.fileName,
          modified: backup.modified,
          sizeBytes: backup.sizeBytes,
          kind: BackupKind.manual,
        ),
        mode: RestoreMode.merge,
      );

      expect((await repository.getArticle(article.id)).content, hugeBody);
      final history = await repository.listHistory(article.id);
      expect(
        history.map((revision) => revision.content),
        contains('remote small'),
      );
    },
  );

  test('merge restore keeps books created after the snapshot', () async {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Zephyr',
      packageName: 'zephyr',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final directory = await Directory.systemTemp.createTemp('zephyr-merge-');
    final database = PureWriterDatabase(
      supportDirectory: () async => directory,
    );
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    await database.openDefaultLibrary();
    final repository = PureWriterWritingLibraryRepository(database);
    final backup = await repository.createBackup(kind: BackupKind.manual);
    final snapshot = await File(backup.path)
        .copy('${directory.path}/snapshot.pwb');
    final newerBook = await repository.createFolder(name: 'New book');

    await repository.restoreBackup(
      entry: BackupEntry(
        path: snapshot.path,
        fileName: 'snapshot.pwb',
        modified: backup.modified,
        sizeBytes: backup.sizeBytes,
        kind: BackupKind.manual,
      ),
      mode: RestoreMode.merge,
    );

    final books = (await repository.loadLibrary()).folders;
    expect(books.map((book) => book.id), contains(newerBook.id));
  });

  test('equal-time merge keeps local text and preserves remote text', () async {
    final setup = await _conflictingArticles();
    addTearDown(setup.close);
    await setup.database.database.update(
      'Article',
      {'updateTime': setup.remoteTime},
      where: 'id = ?',
      whereArgs: [setup.articleId],
    );

    await setup.repository.restoreBackup(
      entry: setup.backup,
      mode: RestoreMode.merge,
    );

    expect(
      (await setup.repository.getArticle(setup.articleId)).content,
      'local text',
    );
    final history = await setup.repository.listHistory(setup.articleId);
    expect(
      history.map((revision) => revision.content),
      contains('remote text'),
    );
  });

  test('newer remote merge retains replaced local text in history', () async {
    final setup = await _conflictingArticles();
    addTearDown(setup.close);
    await setup.database.database.update(
      'Article',
      {'updateTime': setup.remoteTime - 1},
      where: 'id = ?',
      whereArgs: [setup.articleId],
    );

    await setup.repository.restoreBackup(
      entry: setup.backup,
      mode: RestoreMode.merge,
    );

    expect(
      (await setup.repository.getArticle(setup.articleId)).content,
      'local text',
    );
    final history = await setup.repository.listHistory(setup.articleId);
    expect(
      history.map((revision) => revision.content),
      contains('remote text'),
    );
  });

  test('merge restore keeps edits from both devices', () async {
    final setup = await _twoDeviceLibrary();
    addTearDown(setup.close);

    await setup.repository.restoreBackup(
      entry: setup.cloudBackup,
      mode: RestoreMode.merge,
    );

    final library = await setup.repository.loadLibrary();
    final byTitle = {
      for (final article in library.articles) article.title: article,
    };
    expect(
      (await setup.repository.getArticle(byTitle['第一章']!.id)).content,
      '共同正文\n甲的修改',
    );
    expect(
      (await setup.repository.getArticle(byTitle['第二章']!.id)).content,
      '共同正文\n乙的修改',
    );
    final sameChapter = await setup.repository.getArticle(byTitle['同一章']!.id);
    expect(sameChapter.content, contains('甲加了一段'));
    expect(sameChapter.content, contains('乙加了一段'));
  });
}

Future<
  ({
    PureWriterDatabase database,
    PureWriterWritingLibraryRepository repository,
    BackupEntry backup,
    String articleId,
    int remoteTime,
    Future<void> Function() close,
  })
>
_conflictingArticles() async {
  // ignore: invalid_use_of_visible_for_testing_member
  PackageInfo.setMockInitialValues(
    appName: 'Zephyr',
    packageName: 'zephyr',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final directory = await Directory.systemTemp.createTemp('zephyr-conflict-');
  final database = PureWriterDatabase(supportDirectory: () async => directory);
  await database.openDefaultLibrary();
  final repository = PureWriterWritingLibraryRepository(database);
  final article = await repository.createArticle(
    folderId: PureWriterDatabase.defaultFolderId,
  );
  await repository.saveArticle(article.copyWith(content: 'remote text'));
  final rows = await database.database.query(
    'Article',
    columns: ['updateTime'],
    where: 'id = ?',
    whereArgs: [article.id],
  );
  final remoteTime = rows.single['updateTime']! as int;
  final created = await repository.createBackup(kind: BackupKind.manual);
  final snapshot = await File(created.path)
      .copy('${directory.path}/remote.pwb');
  await repository.saveArticle(
    (await repository.getArticle(article.id)).copyWith(content: 'local text'),
  );
  return (
    database: database,
    repository: repository,
    backup: BackupEntry(
      path: snapshot.path,
      fileName: 'remote.pwb',
      modified: created.modified,
      sizeBytes: created.sizeBytes,
      kind: BackupKind.manual,
    ),
    articleId: article.id,
    remoteTime: remoteTime,
    close: () async {
      await database.close();
      await directory.delete(recursive: true);
    },
  );
}

Future<
  ({
    PureWriterWritingLibraryRepository repository,
    BackupEntry cloudBackup,
    Future<void> Function() close,
  })
>
_twoDeviceLibrary() async {
  // ignore: invalid_use_of_visible_for_testing_member
  PackageInfo.setMockInitialValues(
    appName: 'Zephyr',
    packageName: 'zephyr',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final directory = await Directory.systemTemp.createTemp('zephyr-two-device-');
  final database = PureWriterDatabase(supportDirectory: () async => directory);
  await database.openDefaultLibrary();
  final repository = PureWriterWritingLibraryRepository(database);
  final folderId = PureWriterDatabase.defaultFolderId;
  final chapterOne = await repository.createArticle(folderId: folderId);
  final chapterTwo = await repository.createArticle(folderId: folderId);
  final sameChapter = await repository.createArticle(folderId: folderId);
  await repository.renameArticle(articleId: chapterOne.id, title: '第一章');
  await repository.renameArticle(articleId: chapterTwo.id, title: '第二章');
  await repository.renameArticle(articleId: sameChapter.id, title: '同一章');
  await repository.saveArticle(
    (await repository.getArticle(chapterOne.id)).copyWith(content: '共同正文'),
  );
  await repository.saveArticle(
    (await repository.getArticle(chapterTwo.id)).copyWith(content: '共同正文'),
  );
  await repository.saveArticle(
    (await repository.getArticle(sameChapter.id)).copyWith(content: '共同正文'),
  );
  final shared = await repository.createBackup(kind: BackupKind.manual);
  final sharedCopy = await File(shared.path)
      .copy('${directory.path}/shared.pwb');

  await repository.saveArticle(
    (await repository.getArticle(chapterOne.id))
        .copyWith(content: '共同正文\n甲的修改'),
  );
  await repository.saveArticle(
    (await repository.getArticle(sameChapter.id))
        .copyWith(content: '共同正文\n甲加了一段'),
  );
  final cloud = await repository.createBackup(kind: BackupKind.manual);
  final cloudCopy = await File(cloud.path).copy('${directory.path}/cloud.pwb');

  await repository.restoreBackup(
    entry: BackupEntry(
      path: sharedCopy.path,
      fileName: 'shared.pwb',
      modified: shared.modified,
      sizeBytes: await sharedCopy.length(),
      kind: BackupKind.manual,
    ),
    mode: RestoreMode.overwrite,
  );
  await repository.saveArticle(
    (await repository.getArticle(chapterTwo.id))
        .copyWith(content: '共同正文\n乙的修改'),
  );
  await repository.saveArticle(
    (await repository.getArticle(sameChapter.id))
        .copyWith(content: '共同正文\n乙加了一段'),
  );

  return (
    repository: repository,
    cloudBackup: BackupEntry(
      path: cloudCopy.path,
      fileName: 'cloud.pwb',
      modified: cloud.modified,
      sizeBytes: await cloudCopy.length(),
      kind: BackupKind.manual,
    ),
    close: () async {
      await database.close();
      await directory.delete(recursive: true);
    },
  );
}
