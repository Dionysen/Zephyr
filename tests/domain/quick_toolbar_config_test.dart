import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';

void main() {
  test('defaults pin undo/paste and keep tools reserved', () {
    final config = QuickToolbarConfig.defaults;
    expect(config.fixedZoneIds, [
      QuickTool.toolsId,
      QuickTool.undoId,
      QuickTool.pasteId,
    ]);
    expect(config.customIds, [QuickTool.indentId]);
  });

  test('round-trips phrase catalog and layout', () {
    final phrase = QuickTool(
      id: 'phrase-1',
      kind: QuickToolKind.phrase,
      label: '署名',
      payload: '——作者',
    );
    final original = QuickToolbarConfig(
      pinnedIds: const [QuickTool.undoId],
      customIds: [phrase.id, QuickTool.formatId],
      catalog: [...QuickTool.builtins, phrase],
    );

    final restored = QuickToolbarConfig.fromJson(original.toJson());
    expect(restored.pinnedIds, [QuickTool.undoId]);
    expect(restored.customIds, [phrase.id, QuickTool.formatId]);
    expect(restored.toolById(phrase.id)?.payload, '——作者');
    expect(restored.fixedZoneIds.first, QuickTool.toolsId);
  });

  test('normalized drops duplicates and caps pinned slots', () {
    final config = QuickToolbarConfig(
      pinnedIds: const [
        QuickTool.undoId,
        QuickTool.pasteId,
        QuickTool.indentId,
        QuickTool.formatId,
        'extra',
        QuickTool.undoId,
      ],
      customIds: const [QuickTool.pasteId, QuickTool.indentId],
      catalog: QuickTool.builtins,
    ).normalized();

    expect(config.pinnedIds.length, lessThanOrEqualTo(QuickToolbarConfig.maxPinned));
    expect(config.pinnedIds.toSet().length, config.pinnedIds.length);
    expect(config.customIds, isEmpty);
    expect(config.fixedZoneIds.contains(QuickTool.toolsId), isTrue);
  });
}
