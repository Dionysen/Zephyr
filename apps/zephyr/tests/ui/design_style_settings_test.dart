import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_primitives/flutter_primitives.dart';
import 'package:zephyr/app/product_theme.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/core/settings/zephyr_settings_choice_tile.dart';
import 'package:zephyr/ui/core/settings/zephyr_settings_app_bar.dart';
import 'package:zephyr/ui/core/settings/zephyr_settings_number_picker.dart';
import 'package:zephyr/ui/core/zephyr_bottom_sheet.dart';
import 'package:zephyr/ui/core/zephyr_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('design style names parse explicitly', () {
    expect(DesignStyle.parse('material'), DesignStyle.material);
    expect(DesignStyle.parse('cupertino'), DesignStyle.cupertino);
    expect(DesignStyle.parse('custom'), DesignStyle.custom);
    expect(() => DesignStyle.parse('unknown'), throwsArgumentError);
  });

  for (final style in DesignStyle.values) {
    for (final width in [400.0, 1200.0]) {
      testWidgets(
        '${style.name} settings use the selected design language at ${width.toInt()}px',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var enabled = false;
          var selected = 'plain';
          var size = 12.0;
          await tester.pumpWidget(
            DesignStyleScope(
              style: style,
              child: MaterialApp(
                theme: productTheme(style, ThemeTokens.defaults),
                home: StatefulBuilder(
                  builder: (context, setState) => AdaptiveSettingsPage(
                    title: 'Settings',
                    groups: [
                      SettingsGroup(
                        title: 'Editor',
                        items: [
                          SettingsToggleItem(
                            title: 'Auto save',
                            icon: Icons.save,
                            value: enabled,
                            onChanged: (value) =>
                                setState(() => enabled = value),
                          ),
                          SettingsChoiceItem<String>(
                            title: 'Format',
                            icon: Icons.description,
                            value: selected,
                            choices: const [
                              SettingsChoice(value: 'plain', label: 'Plain'),
                              SettingsChoice(
                                value: 'markdown',
                                label: 'Markdown',
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => selected = value),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          if (style == DesignStyle.cupertino) {
            expect(find.byType(CupertinoPageScaffold), findsOneWidget);
            expect(find.byType(CupertinoSwitch), findsOneWidget);
            expect(find.byType(CupertinoListSection), findsOneWidget);
            expect(find.byType(Scaffold), findsNothing);
            await tester.tap(find.byType(CupertinoSwitch));
          } else {
            expect(find.byType(Scaffold), findsOneWidget);
            expect(find.byType(Switch), findsOneWidget);
            await tester.tap(find.byType(Switch));
          }
          await tester.pumpAndSettle();
          expect(enabled, isTrue);

          await tester.tap(find.text('Plain'));
          await tester.pumpAndSettle();
          if (style == DesignStyle.cupertino) {
            expect(
              find.byType(
                width < AdaptiveBreakpoints.compact
                    ? CupertinoActionSheet
                    : CupertinoAlertDialog,
              ),
              findsOneWidget,
            );
          } else {
            expect(
              find.byType(
                width < AdaptiveBreakpoints.compact ? BottomSheet : AlertDialog,
              ),
              findsOneWidget,
            );
          }
          await tester.tap(find.text('Markdown'));
          await tester.pumpAndSettle();
          expect(selected, 'markdown');

          if (style == DesignStyle.cupertino) {
            if (width < AdaptiveBreakpoints.compact) {
              await tester.tap(find.text('12'));
              await tester.pumpAndSettle();
              expect(find.byType(CupertinoAlertDialog), findsOneWidget);
              await _dragCupertinoSlider(tester);
              await tester.pumpAndSettle();
              await tester.tap(find.text('OK'));
            } else {
              await _dragCupertinoSlider(tester);
            }
            await tester.pumpAndSettle();
            expect(size, greaterThan(12));
          }
        },
      );
    }
  }

  testWidgets('Zephyr setting pickers use Cupertino dialogs', (tester) async {
    String? choice;
    double? number;
    await tester.pumpWidget(
      DesignStyleScope(
        style: DesignStyle.cupertino,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      choice = await showZephyrSettingsChoicePicker<String>(
                        context,
                        title: 'Format',
                        choices: const [
                          ZephyrSettingsChoice(value: 'plain', label: 'Plain'),
                          ZephyrSettingsChoice(
                            value: 'markdown',
                            label: 'Markdown',
                          ),
                        ],
                        selected: 'plain',
                      );
                    },
                    child: const Text('Choose'),
                  ),
                  TextButton(
                    onPressed: () async {
                      number = await showZephyrSettingsNumberPicker(
                        context,
                        title: 'Size',
                        value: 12,
                        min: 10,
                        max: 20,
                        defaultValue: 12,
                      );
                    },
                    child: const Text('Number'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('Markdown'));
    await tester.pumpAndSettle();
    expect(choice, 'markdown');

    await tester.tap(find.text('Number'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.byType(CupertinoSlider), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(number, 12);
  });

  testWidgets('Zephyr list modal uses Cupertino popup surface', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      DesignStyleScope(
        style: DesignStyle.cupertino,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showZephyrModalSheet<void>(
                  context: context,
                  builder: (popupContext) => SizedBox(
                    height: 120,
                    child: CupertinoButton(
                      onPressed: () {
                        tapped = true;
                        Navigator.of(popupContext).pop();
                      },
                      child: const Text('Choose'),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoPopupSurface), findsOneWidget);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('plain confirmation keeps its callback in Cupertino style', (
    tester,
  ) async {
    bool? confirmed;
    await tester.pumpWidget(
      DesignStyleScope(
        style: DesignStyle.cupertino,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await showZephyrDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text('Continue?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
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
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('Zephyr settings bar uses Cupertino navigation', (tester) async {
    var wentBack = false;
    await tester.pumpWidget(
      DesignStyleScope(
        style: DesignStyle.cupertino,
        child: MaterialApp(
          home: CupertinoPageScaffold(
            child: Column(
              children: [
                ZephyrSettingsAppBar(
                  title: 'Settings',
                  onBack: () => wentBack = true,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.back));
    expect(wentBack, isTrue);
  });
}

Future<void> _dragCupertinoSlider(WidgetTester tester) async {
  final finder = find.byType(CupertinoSlider);
  final topLeft = tester.getTopLeft(finder);
  final size = tester.getSize(finder);
  final thumb = topLeft + Offset(15 + (size.width - 30) * 0.2, size.height / 2);
  await tester.dragFrom(thumb, const Offset(80, 0));
}
