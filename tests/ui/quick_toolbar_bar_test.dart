import 'package:fake_async/fake_async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';
import 'package:zephyr/domain/repositories/editor_preferences_repository.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_tool_button.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_bar.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_drawer.dart';
import 'package:zephyr/ui/core/zephyr_swipe_drawer.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_host.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/tools_panel_toggle_gate.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/workspace_editor_bridge.dart';
import 'package:zephyr/ui/features/editor/view_models/editor_preferences_view_model.dart';
import 'package:zephyr/ui/features/editor/view_models/quick_toolbar_view_model.dart';
import 'package:zephyr/domain/repositories/quick_toolbar_preferences_repository.dart';
import 'package:zephyr/ui/features/settings/view_models/font_library.dart';

void main() {
  test('symbol phrase labels are short punctuation only', () {
    expect(quickToolbarLabelLooksLikeSymbol('"'), isTrue);
    expect(quickToolbarLabelLooksLikeSymbol('「」'), isTrue);
    expect(quickToolbarLabelLooksLikeSymbol('—'), isTrue);
    expect(quickToolbarLabelLooksLikeSymbol('署名'), isFalse);
    expect(quickToolbarLabelLooksLikeSymbol('Hello'), isFalse);
    expect(quickToolbarLabelLooksLikeSymbol('……完'), isFalse);
  });

  test('compact chip label maps fullwidth parens to proportional ASCII', () {
    expect(compactSymbolChipLabel('（）'), '()');
    expect(compactSymbolChipLabel('“”'), '“”');
  });

  testWidgets(
    'default long punctuation shows short labels and sends full text',
    (tester) async {
      final pressed = <QuickTool>[];
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: Row(
                children: [
                  for (final tool in QuickTool.defaultPhrases.where(
                    (tool) =>
                        tool.id == 'default-dash' ||
                        tool.id == 'default-ellipsis',
                  ))
                    QuickToolButton(
                      tool: tool,
                      foreground: Colors.black,
                      onPressed: () => pressed.add(tool),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('——'), findsNothing);
      expect(find.text('……'), findsNothing);
      await tester.tap(find.text('—'));
      await tester.tap(find.text('…'));
      expect(pressed.map((tool) => tool.payload), ['——', '……']);
    },
  );

  testWidgets('fixed tools stay outside the horizontal scroller', (
    tester,
  ) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: QuickToolbarBar(
            config: QuickToolbarConfig.defaults,
            foreground: Colors.white,
            toolsDrawerOpen: false,
            canUndo: true,
            onToolPressed: (tool) => pressed.add(tool.id),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.content_paste_rounded), findsOneWidget);
    expect(find.byIcon(Icons.format_indent_increase_rounded), findsOneWidget);

    final scrollable = find.descendant(
      of: find.byType(QuickToolbarBar),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    // Indent lives in the scrollable custom zone.
    expect(
      find.descendant(
        of: scrollable,
        matching: find.byIcon(Icons.format_indent_increase_rounded),
      ),
      findsOneWidget,
    );
    // Undo stays in the fixed (non-scroll) zone.
    expect(
      find.descendant(
        of: scrollable,
        matching: find.byIcon(Icons.undo_rounded),
      ),
      findsNothing,
    );

    await tester.tap(find.byIcon(Icons.apps_rounded));
    expect(pressed, [QuickTool.toolsId]);
  });

  testWidgets('custom tools scroll horizontally with Material stretch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: QuickToolbarBar(
                config: QuickToolbarConfig.defaults,
                foreground: Colors.black,
                toolsDrawerOpen: false,
                canUndo: true,
                onToolPressed: (_) {},
                onReorderCustom: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );

    final scrollable = find.descendant(
      of: find.byType(QuickToolbarBar),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
    await tester.drag(scrollable, const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('short custom zone still accepts edge drag for stretch', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 240,
              child: QuickToolbarBar(
                config: QuickToolbarConfig(
                  pinnedIds: const [QuickTool.undoId, QuickTool.pasteId],
                  customIds: const [QuickTool.indentId],
                  catalog: QuickTool.builtins,
                ),
                foreground: Colors.black,
                toolsDrawerOpen: false,
                canUndo: true,
                onToolPressed: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final scrollable = find.descendant(
      of: find.byType(QuickToolbarBar),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, 0);
    expect(position.physics.shouldAcceptUserOffset(position), isTrue);
    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
  });

  testWidgets('long-press drag reorders custom-zone tools', (tester) async {
    var customIds = <String>[QuickTool.indentId, QuickTool.formatId];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return QuickToolbarBar(
                config: QuickToolbarConfig(
                  pinnedIds: const [QuickTool.undoId, QuickTool.pasteId],
                  customIds: customIds,
                  catalog: QuickTool.builtins,
                ),
                foreground: Colors.white,
                toolsDrawerOpen: false,
                canUndo: true,
                onToolPressed: (_) {},
                onReorderCustom: (oldIndex, newIndex) {
                  setState(() {
                    final next = List<String>.from(customIds);
                    final id = next.removeAt(oldIndex);
                    next.insert(newIndex.clamp(0, next.length), id);
                    customIds = next;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    final indent = find.byIcon(Icons.format_indent_increase_rounded);
    final format = find.byIcon(Icons.auto_fix_high_rounded);
    expect(
      tester.getTopLeft(indent).dx,
      lessThan(tester.getTopLeft(format).dx),
    );

    final gesture = await tester.startGesture(tester.getCenter(indent));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveTo(tester.getCenter(format) + const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(customIds.indexOf(QuickTool.indentId), greaterThan(0));
  });

  testWidgets('tools drawer keeps toolbar while keyboard inset is latched', (
    tester,
  ) async {
    final toolbar = QuickToolbarViewModel(_Repo());
    final bridge = WorkspaceEditorBridge()..setBodyFocused(true);
    final editorPreferences = _editorPreferences();
    addTearDown(editorPreferences.dispose);
    toolbar.openToolsDrawer(keyboardHeight: 300);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: Scaffold(
            body: QuickToolbarHost(
              toolbar: toolbar,
              bridge: bridge,
              foreground: Colors.white,
              editorPreferences: editorPreferences,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(QuickToolbarBar), findsOneWidget);
    expect(
      tester.getSize(find.byType(QuickToolbarBar)).height,
      QuickToolButton.height,
    );
    expect(find.text('Edit toolbar'), findsOneWidget);
    expect(find.text('Line height'), findsOneWidget);
    expect(find.text('Font size'), findsOneWidget);

    // Obstruction replaces the latched panel so total cover stays constant.
    expect(
      QuickToolbarHost.bottomObstruction(
        visible: true,
        drawerOpen: true,
        keyboardInset: 120,
        panelHeight: 300,
      ),
      QuickToolButton.height + 300 - 120,
    );

    toolbar.restoreImeFromTools();
    expect(toolbar.toolsDrawerOpen, isFalse);
    expect(toolbar.holdingPanelForIme, isTrue);
    expect(toolbar.usesFixedPanel, isTrue);

    // Hold must not release early — that drops effective cover and bounces.
    toolbar.rememberKeyboardHeight(300 * 0.95);
    expect(toolbar.holdingPanelForIme, isTrue);
    toolbar.rememberKeyboardHeight(300);
    expect(toolbar.holdingPanelForIme, isFalse);
  });

  testWidgets('tools panel right-swipe does not open library sidebar', (
    tester,
  ) async {
    final toolbar = QuickToolbarViewModel(_Repo());
    final bridge = WorkspaceEditorBridge()
      ..setBodyFocused(true)
      ..setSuppressBodyIme(true);
    final editorPreferences = _editorPreferences();
    addTearDown(editorPreferences.dispose);
    toolbar.openToolsDrawer(keyboardHeight: 300);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ZephyrSwipeDrawer(
          drawerWidth: 280,
          drawer: const ColoredBox(color: Color(0xFFFF0000)),
          body: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.zero),
            child: QuickToolbarHost(
              toolbar: toolbar,
              bridge: bridge,
              foreground: Colors.white,
              editorPreferences: editorPreferences,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final drawer = find.byType(QuickToolbarDrawer);
    final rect = tester.getRect(drawer);
    final start = Offset(rect.center.dx, rect.top + rect.height * 0.8);
    await tester.dragFrom(start, const Offset(120, 0));
    await tester.pumpAndSettle();

    final swipe = ZephyrSwipeDrawer.of(tester.element(find.byType(QuickToolbarHost)));
    expect(swipe.isOpen, isFalse);
  });

  testWidgets('tools drawer survives transient body focus loss', (tester) async {
    final toolbar = QuickToolbarViewModel(_Repo());
    final bridge = WorkspaceEditorBridge()
      ..setBodyFocused(true)
      ..setSuppressBodyIme(true);
    final editorPreferences = _editorPreferences();
    addTearDown(editorPreferences.dispose);
    toolbar.openToolsDrawer(keyboardHeight: 300);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: Scaffold(
            body: QuickToolbarHost(
              toolbar: toolbar,
              bridge: bridge,
              foreground: Colors.white,
              editorPreferences: editorPreferences,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    bridge.setBodyFocused(false);
    await tester.pump();
    expect(toolbar.toolsDrawerOpen, isTrue);
    expect(find.text('Line height'), findsOneWidget);

    final drawer = find.byType(QuickToolbarDrawer);
    final box = tester.getRect(drawer);
    await tester.tapAt(Offset(box.center.dx, box.top + box.height * 0.75));
    await tester.pumpAndSettle();
    expect(toolbar.toolsDrawerOpen, isTrue);
  });

  test('body IME rising while drawer open keeps the drawer', () {
    final toolbar = QuickToolbarViewModel(_Repo());
    toolbar.openToolsDrawer(keyboardHeight: 300);
    // Keyboard animating away after hide — must not dismiss the drawer.
    toolbar.reportKeyboardInset(200);
    toolbar.reportKeyboardInset(50);
    toolbar.reportKeyboardInset(0);
    expect(toolbar.toolsDrawerOpen, isTrue);

    // Tap/scroll on the article may briefly raise IME; panel stays until
    // tools toggle or body focus loss.
    toolbar.reportKeyboardInset(80);
    expect(toolbar.toolsDrawerOpen, isTrue);
    expect(toolbar.holdingPanelForIme, isFalse);
  });

  test(
    'openToolsDrawer keeps latched height when live inset is collapsing',
    () {
      final toolbar = QuickToolbarViewModel(_Repo());
      toolbar.openToolsDrawer(keyboardHeight: 300);
      toolbar.closeToolsDrawer();
      toolbar.openToolsDrawer(keyboardHeight: 120);
      expect(toolbar.toolsPanelHeight, 300);
    },
  );

  test('tools toggle gate coalesces double-tap to no-op', () {
    fakeAsync((async) {
      var open = false;
      final commits = <bool>[];
      final gate = ToolsPanelToggleGate(
        actionDelay: const Duration(milliseconds: 140),
        busyTimeout: const Duration(milliseconds: 450),
        isDrawerOpen: () => open,
        onCommit: (next) {
          open = next;
          commits.add(next);
        },
      );

      gate.toggle();
      gate.toggle();
      async.elapse(const Duration(milliseconds: 140));
      expect(commits, isEmpty);
      expect(open, isFalse);

      gate.toggle();
      async.elapse(const Duration(milliseconds: 140));
      expect(commits, [true]);
      expect(open, isTrue);

      gate.dispose();
    });
  });

  test('tools toggle gate queues intent until IME settles', () {
    fakeAsync((async) {
      var open = false;
      final commits = <bool>[];
      final gate = ToolsPanelToggleGate(
        actionDelay: Duration.zero,
        busyTimeout: const Duration(milliseconds: 450),
        isDrawerOpen: () => open,
        onCommit: (next) {
          open = next;
          commits.add(next);
        },
      );

      gate.toggle();
      async.elapse(Duration.zero);
      expect(commits, [true]);
      expect(gate.isBusy, isTrue);

      // Close while the open transition is still busy — apply after settle.
      gate.toggle();
      async.elapse(Duration.zero);
      expect(commits, [true]);

      gate.markSettled();
      expect(commits, [true, false]);
      expect(open, isFalse);
      expect(gate.isBusy, isTrue);

      gate.markSettled();
      expect(gate.isBusy, isFalse);

      gate.dispose();
    });
  });

  testWidgets('rapid tools taps on host do not stack drawer toggles', (
    tester,
  ) async {
    final toolbar = QuickToolbarViewModel(_Repo());
    final bridge = WorkspaceEditorBridge()..setBodyFocused(true);
    final editorPreferences = _editorPreferences();
    addTearDown(editorPreferences.dispose);
    toolbar.openToolsDrawer(keyboardHeight: 300);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.zero),
          child: Scaffold(
            body: QuickToolbarHost(
              toolbar: toolbar,
              bridge: bridge,
              foreground: Colors.white,
              editorPreferences: editorPreferences,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final tools = find.byIcon(Icons.apps_rounded);
    expect(tools, findsOneWidget);

    // Double-tap while open → coalesced no-op (stay open).
    await tester.tap(tools);
    await tester.tap(tools);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    expect(toolbar.toolsDrawerOpen, isTrue);
    expect(find.byType(QuickToolbarBar), findsOneWidget);

    await tester.tap(tools);
    await tester.pump(const Duration(milliseconds: 140));
    expect(toolbar.toolsDrawerOpen, isFalse);
    expect(toolbar.holdingPanelForIme, isTrue);
    expect(find.byType(QuickToolbarBar), findsOneWidget);
  });
}

class _Repo implements QuickToolbarPreferencesRepository {
  @override
  Future<QuickToolbarConfig> load() async => QuickToolbarConfig.defaults;

  @override
  Future<void> save(QuickToolbarConfig config) async {}
}

EditorPreferencesViewModel _editorPreferences() {
  final fonts = FontLibrary(_FontRepository());
  return EditorPreferencesViewModel(_MemoryEditorRepository(), fonts);
}

class _MemoryEditorRepository implements EditorPreferencesRepository {
  @override
  Future<EditorPreferences> load() async => EditorPreferences.defaults;

  @override
  Future<void> save(EditorPreferences preferences) async {}
}

class _FontRepository implements SystemFontRepository {
  @override
  Future<List<SystemFont>> listFonts() async => const [];

  @override
  Future<String?> loadFont(SystemFont font) async => font.family;

  @override
  Future<SystemFont?> importFont(String sourcePath) async => null;

  @override
  Future<bool> deleteImportedFont(SystemFont font) async => false;
}
