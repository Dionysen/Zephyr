import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/core/zephyr_markdown_body.dart';

void main() {
  testWidgets('bold in sentence with corner quotes renders heavy weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZephyrMarkdownBody(
            data: '这是**「重要」**的内容',
            foreground: Colors.black,
            selectable: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final hasBold = richTexts.any((rich) {
      var found = false;
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          final w = span.style?.fontWeight;
          if (w != null && w.value >= FontWeight.w700.value) {
            if (span.text?.contains('重要') ?? false) found = true;
          }
          for (final c in span.children ?? const <InlineSpan>[]) {
            walk(c);
          }
        }
      }
      walk(rich.text);
      return found;
    });
    expect(hasBold, isTrue);
  });
}
