import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';
import 'package:zephyr/domain/repositories/quick_toolbar_preferences_repository.dart';
import 'package:zephyr/ui/features/editor/view_models/quick_toolbar_view_model.dart';

void main() {
  late _MemoryToolbarRepository repository;
  late QuickToolbarViewModel model;

  setUp(() {
    repository = _MemoryToolbarRepository();
    model = QuickToolbarViewModel(repository);
    addTearDown(model.dispose);
  });

  test('loads and normalizes saved toolbar layout', () async {
    repository.config = QuickToolbarConfig(
      pinnedIds: const [QuickTool.toolsId, QuickTool.undoId, QuickTool.undoId],
      customIds: const [QuickTool.pasteId, 'missing'],
      catalog: QuickTool.builtins,
    );

    await model.load();

    expect(model.config.pinnedIds, [QuickTool.undoId]);
    expect(model.config.customIds, [QuickTool.pasteId]);
  });

  test(
    'moving tools keeps each placement unique and reserves the tools button',
    () {
      model.moveToPinned(QuickTool.indentId, index: 0);
      expect(model.config.pinnedIds.first, QuickTool.indentId);
      expect(model.config.customIds, isNot(contains(QuickTool.indentId)));

      model.moveToCustom(QuickTool.indentId);
      expect(model.config.pinnedIds, isNot(contains(QuickTool.indentId)));
      expect(model.config.customIds.last, QuickTool.indentId);
      expect(
        model.config.customIds.take(QuickTool.defaultPhrases.length),
        QuickTool.defaultPhrases.map((tool) => tool.id),
      );

      final before = model.config.fixedZoneIds;
      model.moveToPinned(QuickTool.toolsId);
      model.removeTool(QuickTool.toolsId);
      expect(model.config.fixedZoneIds, before);
    },
  );

  test('phrases can be added, edited, and removed from the catalog', () {
    model.addPhrase(label: '  Signature  ', payload: '— writer');
    final id = model.config.customIds.last;
    expect(model.config.toolById(id)?.label, 'Signature');

    model.updatePhrase(id, label: '  Closing ', payload: 'The end');
    expect(model.config.toolById(id)?.label, 'Closing');
    expect(model.config.toolById(id)?.payload, 'The end');

    model.removeTool(id);
    expect(model.config.toolById(id), isNull);
    expect(model.config.placedIds, isNot(contains(id)));
  });

  test('default punctuation can be edited and removed permanently', () async {
    const dashId = 'default-dash';
    const ellipsisId = 'default-ellipsis';
    model.updatePhrase(dashId, label: 'dash', payload: '--');
    model.removeTool(ellipsisId);

    expect(model.config.toolById(dashId)?.label, 'dash');
    expect(model.config.toolById(dashId)?.payload, '--');
    expect(model.config.toolById(ellipsisId), isNull);
    expect(model.config.customIds, isNot(contains(ellipsisId)));

    final restored = QuickToolbarConfig.fromJson(model.config.toJson());
    expect(restored.toolById(dashId)?.payload, '--');
    expect(restored.toolById(ellipsisId), isNull);
  });

  test('empty phrase input and duplicate builtins do not change layout', () {
    final before = model.config.toJson();
    model.addPhrase(label: '  ', payload: 'text');
    model.addPhrase(label: 'valid', payload: '');
    model.addBuiltin(QuickTool.undo);
    model.addBuiltin(QuickTool.tools);
    expect(model.config.toJson(), before);
  });

  test('drawer holds its keyboard height until the IME fills the panel', () {
    model.rememberKeyboardHeight(300);
    model.openToolsDrawer(keyboardHeight: 180);
    expect(model.toolsPanelHeight, 300);
    expect(model.usesFixedPanel, isTrue);

    model.restoreImeFromTools();
    expect(model.holdingPanelForIme, isTrue);
    model.rememberKeyboardHeight(290);
    expect(model.holdingPanelForIme, isTrue);
    model.rememberKeyboardHeight(300);
    expect(model.holdingPanelForIme, isFalse);
    expect(model.usesFixedPanel, isFalse);
  });

  test('rising keyboard inset does not dismiss an open tools drawer', () {
    model.openToolsDrawer(keyboardHeight: 250);
    model.reportKeyboardInset(0);
    model.reportKeyboardInset(100);

    expect(model.toolsDrawerOpen, isTrue);
    expect(model.holdingPanelForIme, isFalse);
  });
}

class _MemoryToolbarRepository implements QuickToolbarPreferencesRepository {
  QuickToolbarConfig config = QuickToolbarConfig.defaults;

  @override
  Future<QuickToolbarConfig> load() async => config;

  @override
  Future<void> save(QuickToolbarConfig value) async {
    config = value;
  }
}
