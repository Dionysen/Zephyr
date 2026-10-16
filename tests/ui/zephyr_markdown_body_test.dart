import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/core/zephyr_markdown_body.dart';

void main() {
  testWidgets('fenced code blocks expose a horizontal scrollable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final markdown = '```\n${'x' * 120}\n```';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: ZephyrMarkdownBody(
                data: markdown,
                foreground: Colors.black,
                selectable: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);

    final scrollView = tester.widget<SingleChildScrollView>(horizontal);
    final controller = scrollView.controller!;
    await tester.pumpAndSettle();
    expect(controller.position.maxScrollExtent, greaterThan(0));
  });
}
