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
}
