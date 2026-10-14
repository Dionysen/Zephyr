import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/workspace/views/workspace_mobile_tools_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mobile tools drawer lists square actions and runs onTap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  showWorkspaceMobileToolsDrawer(
                    context,
                    title: 'More',
                    order: const ['settings', 'search'],
                    onReorder: (_) {},
                    actions: [
                      WorkspaceMobileDrawerAction(
                        id: 'search',
                        label: 'Search',
                        icon: Icons.search,
                        onTap: () => tapped = true,
                      ),
                      WorkspaceMobileDrawerAction(
                        id: 'settings',
                        label: 'Settings',
                        icon: Icons.settings_outlined,
                        onTap: () {},
                      ),
                    ],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('More'), findsOneWidget);
    expect(find.textContaining('Long-press'), findsOneWidget);
    // Persisted order puts Settings before Search.
    final settingsY = tester.getTopLeft(find.text('Settings')).dy;
    final searchY = tester.getTopLeft(find.text('Search')).dy;
    expect(settingsY, lessThanOrEqualTo(searchY));

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(find.text('More'), findsNothing);
  });
}
