import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_tool_button.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_bar.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_host.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/tools_panel_toggle_gate.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/workspace_editor_bridge.dart';
import 'package:zephyr/ui/features/editor/view_models/quick_toolbar_view_model.dart';
import 'package:zephyr/domain/repositories/quick_toolbar_preferences_repository.dart';

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

  testWidgets('fixed tools stay outside the horizontal scroller', (tester) async {
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

  testWidgets('tools drawer keeps toolbar while keyboard inset is latched', (
    tester,
  ) async {
    final toolbar = QuickToolbarViewModel(_Repo());
    final bridge = WorkspaceEditorBridge()..setBodyFocused(true);
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
    expect(find.text('Tool panel content coming soon'), findsOneWidget);

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

  test('body IME rising while drawer open dismisses the drawer', () {
    final toolbar = QuickToolbarViewModel(_Repo());
    toolbar.openToolsDrawer(keyboardHeight: 300);
    // Keyboard animating away after hide — must not dismiss the drawer.
    toolbar.reportKeyboardInset(200);
    toolbar.reportKeyboardInset(50);
    toolbar.reportKeyboardInset(0);
    expect(toolbar.toolsDrawerOpen, isTrue);

    // User taps the article; IME rises again.
    toolbar.reportKeyboardInset(80);
    expect(toolbar.toolsDrawerOpen, isFalse);
    expect(toolbar.holdingPanelForIme, isTrue);
  });

  test('openToolsDrawer keeps latched height when live inset is collapsing', () {
    final toolbar = QuickToolbarViewModel(_Repo());
    toolbar.openToolsDrawer(keyboardHeight: 300);
    toolbar.closeToolsDrawer();
    toolbar.openToolsDrawer(keyboardHeight: 120);
    expect(toolbar.toolsPanelHeight, 300);
  });

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
