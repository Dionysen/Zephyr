import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zephyr/data/repositories/purewriter_writing_library_repository.dart';
import 'package:zephyr/data/services/purewriter_database.dart';
import 'package:zephyr/domain/models/library_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      'remote text',
    );
    final history = await setup.repository.listHistory(setup.articleId);
    expect(history.map((revision) => revision.content), contains('local text'));
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
