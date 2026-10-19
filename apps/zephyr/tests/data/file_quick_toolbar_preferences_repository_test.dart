import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_quick_toolbar_preferences_repository.dart';
import 'package:zephyr/data/services/quick_toolbar_file_storage.dart';
import 'package:zephyr/domain/models/plain_text_format_option.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';

void main() {
  late Directory directory;
  late QuickToolbarFileStorage storage;
  late FileQuickToolbarPreferencesRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'zephyr-toolbar-storage-',
    );
    addTearDown(() => directory.delete(recursive: true));
    storage = QuickToolbarFileStorage(directoryProvider: () async => directory);
    repository = FileQuickToolbarPreferencesRepository(storage);
  });

  test('missing toolbar file loads the default tool arrangement', () async {
    final config = await repository.load();
    expect(config.pinnedIds, QuickToolbarConfig.defaults.pinnedIds);
    expect(config.customIds, QuickToolbarConfig.defaults.customIds);
    expect(config.customTools.skip(1).toList(), QuickTool.defaultPhrases);
  });

  test('saved layout does not restore removed default punctuation', () async {
    final config = QuickToolbarConfig.defaults;
    await repository.save(
      config.copyWith(
        customIds: config.customIds
            .where((id) => id != 'default-dash')
            .toList(),
        catalog: config.catalog
            .where((tool) => tool.id != 'default-dash')
            .toList(),
      ),
    );

    final restored = await repository.load();
    expect(restored.toolById('default-dash'), isNull);
    expect(restored.customIds, isNot(contains('default-dash')));
  });

  test(
    'saving toolbar layout normalizes duplicates before round trip',
    () async {
      final phrase = const QuickTool(
        id: 'phrase-one',
        kind: QuickToolKind.phrase,
        label: 'Ending',
        payload: 'The end',
      );
      await repository.save(
        QuickToolbarConfig(
          pinnedIds: const [
            QuickTool.toolsId,
            QuickTool.undoId,
            QuickTool.undoId,
          ],
          customIds: const ['phrase-one', QuickTool.undoId],
          catalog: [...QuickTool.builtins, phrase],
        ),
      );

      final config = await repository.load();
      expect(config.pinnedIds, [QuickTool.undoId]);
      expect(config.customIds, ['phrase-one']);
      expect(config.toolById('phrase-one')?.payload, 'The end');
    },
  );

  test('format checkbox ids round-trip through JSON storage', () async {
    final ids = [
      PlainTextFormatOption.removeParagraphBlanks.name,
      PlainTextFormatOption.insertCjkLatinSpaces.name,
    ];
    await repository.save(
      QuickToolbarConfig.defaults.copyWith(formatSelectionIds: ids),
    );

    final restored = await repository.load();
    expect(restored.formatSelectionIds, ids);
  });

  test('invalid toolbar JSON is reported as a format error', () async {
    final file = File('${directory.path}/zephyr/quick-toolbar.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('[]');

    await expectLater(repository.load(), throwsFormatException);
  });
}
