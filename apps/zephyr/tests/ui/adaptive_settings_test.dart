import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_primitives/flutter_primitives.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 1200.0]) {
    testWidgets('settings items work at ${width.toInt()} pixel width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var enabled = false;
      var mode = 'plain';
      var size = 12.0;
      var actionCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => AdaptiveSettingsPage(
              title: 'Settings',
              groups: [
                SettingsGroup(
                  title: 'Editor',
                  icon: Icons.edit,
                  items: [
                    SettingsToggleItem(
                      title: 'Auto save',
                      icon: Icons.save,
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                    SettingsChoiceItem<String>(
                      title: 'Format',
                      icon: Icons.description,
                      value: mode,
                      choices: const [
                        SettingsChoice(value: 'plain', label: 'Plain'),
                        SettingsChoice(value: 'markdown', label: 'Markdown'),
                      ],
                      onChanged: (value) => setState(() => mode = value),
                    ),
                    SettingsNumberItem(
                      title: 'Font size',
                      icon: Icons.format_size,
                      value: size,
                      min: 10,
                      max: 20,
                      divisions: 10,
                      onChanged: (value) => setState(() => size = value),
                    ),
                    SettingsActionItem(
                      title: 'Open details',
                      icon: Icons.open_in_new,
                      onPressed: () => actionCount++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editor'), findsOneWidget);
      expect(
        find.byType(SettingsValueTile),
        width < AdaptiveBreakpoints.compact ? findsNWidgets(3) : findsNothing,
      );
      expect(
        find.byType(SettingsDesktopRow),
        width >= AdaptiveBreakpoints.compact ? findsNWidgets(3) : findsNothing,
      );
      expect(
        find.byType(SettingsSliderRow),
        width >= AdaptiveBreakpoints.compact ? findsOneWidget : findsNothing,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(enabled, isTrue);

      await tester.tap(find.text('Plain'));
      await tester.pumpAndSettle();
      expect(
        find.byType(BottomSheet),
        width < AdaptiveBreakpoints.compact ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(AlertDialog),
        width >= AdaptiveBreakpoints.compact ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Markdown'));
      await tester.pumpAndSettle();
      expect(mode, 'markdown');

      if (width < AdaptiveBreakpoints.compact) {
        await tester.tap(find.text('12'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Slider), const Offset(120, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
      } else {
        await tester.drag(find.byType(Slider), const Offset(120, 0));
      }
      await tester.pumpAndSettle();
      expect(size, greaterThan(12));

      if (width < AdaptiveBreakpoints.compact) {
        await tester.tap(find.text('Open details'));
      } else {
        await tester.tap(find.byIcon(Icons.chevron_right));
      }
      await tester.pumpAndSettle();
      expect(actionCount, 1);
    });
  }

  testWidgets('nullable choice can be selected', (tester) async {
    String? selected = 'plain';
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => AdaptiveSettingsPage(
            title: 'Settings',
            groups: [
              SettingsGroup(
                items: [
                  SettingsChoiceItem<String?>(
                    title: 'Format',
                    icon: Icons.description,
                    value: selected,
                    choices: const [
                      SettingsChoice(value: 'plain', label: 'Plain'),
                      SettingsChoice(value: null, label: 'None'),
                    ],
                    onChanged: (value) => setState(() => selected = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Plain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(find.text('None'), findsOneWidget);
  });
}
