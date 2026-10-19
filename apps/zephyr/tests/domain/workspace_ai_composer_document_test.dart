import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/workspace/models/workspace_ai_composer_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('inserts chapter token at caret and preserves send order', () async {
    final composer = WorkspaceAiComposerController();
    addTearDown(composer.dispose);

    composer.text.text = '总结';
    composer.text.selection = const TextSelection.collapsed(offset: 2);

    composer.insertArticleAtFocus('a1', '第一章');
    composer.text.text = '${composer.text.text}请';
    composer.text.selection = TextSelection.collapsed(
      offset: composer.text.text.length,
    );
    composer.insertArticleAtFocus('a2', '第二章');

    expect(composer.composeDisplayText(), '总结「第一章」请「第二章」');

    final llm = await composeLlmUserMessage(
      composer: composer,
      loadChapterBlock: (id, title) async => '[$id:$title]',
    );
    expect(llm, '总结\n\n[a1:第一章]\n\n请\n\n[a2:第二章]');
  });

  test('token formatter keeps caret on either side of a capsule', () {
    final formatter = AiComposerTokenFormatter();
    final value = TextEditingValue(
      text: 'x${AiComposerTokens.kObjectChar}y',
      selection: const TextSelection.collapsed(offset: 1),
    );
    final kept = formatter.formatEditUpdate(value, value);
    expect(kept.selection.extentOffset, 1);

    final after = TextEditingValue(
      text: value.text,
      selection: const TextSelection.collapsed(offset: 2),
    );
    expect(formatter.formatEditUpdate(after, after).selection.extentOffset, 2);
  });

  testWidgets('chapter token paints as a capsule widget', (tester) async {
    final composer = WorkspaceAiComposerController();
    addTearDown(composer.dispose);
    composer.insertArticleAtFocus('a1', '第一章');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: composer.text)),
      ),
    );

    expect(find.text('第一章'), findsOneWidget);
    final capsule = tester.widget<Text>(find.text('第一章'));
    expect(capsule.style?.backgroundColor, isNull);
  });

  test('token formatter deletes whole capsule on backspace', () {
    final composer = WorkspaceAiComposerController();
    addTearDown(composer.dispose);
    final formatter = AiComposerTokenFormatter();

    composer.insertArticleAtFocus('a1', '第一章');
    final old = composer.text.value;
    final partial = TextEditingValue(
      text: '',
      selection: const TextSelection.collapsed(offset: 0),
    );
    final fixed = formatter.formatEditUpdate(old, partial);
    expect(fixed.text.contains(AiComposerTokens.kObjectChar), isFalse);
  });
}
