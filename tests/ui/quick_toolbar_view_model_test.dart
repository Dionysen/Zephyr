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
      expect(model.config.customIds, isEmpty);

      model.moveToCustom(QuickTool.indentId);
      expect(model.config.pinnedIds, isNot(contains(QuickTool.indentId)));
      expect(model.config.customIds, [QuickTool.indentId]);

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

  test('rising keyboard inset dismisses an open tools drawer', () {
    model.openToolsDrawer(keyboardHeight: 250);
    model.reportKeyboardInset(0);
    model.reportKeyboardInset(100);

    expect(model.toolsDrawerOpen, isFalse);
    expect(model.holdingPanelForIme, isTrue);
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
