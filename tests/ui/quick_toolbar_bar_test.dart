import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_bar.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/quick_toolbar_host.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/workspace_editor_bridge.dart';
import 'package:zephyr/ui/features/editor/view_models/quick_toolbar_view_model.dart';
import 'package:zephyr/domain/repositories/quick_toolbar_preferences_repository.dart';

void main() {
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
    expect(tester.getSize(find.byType(QuickToolbarBar)).height, 36);
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
      36 + 300 - 120,
    );
  });
}

class _Repo implements QuickToolbarPreferencesRepository {
  @override
  Future<QuickToolbarConfig> load() async => QuickToolbarConfig.defaults;

  @override
  Future<void> save(QuickToolbarConfig config) async {}
}
