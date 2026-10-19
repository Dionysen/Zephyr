import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/workspace/models/ai_stream_reveal.dart';

void main() {
  test('reveals one grapheme at a time including CJK', () {
    final reveal = AiStreamReveal();
    reveal.setTargets(text: '你好呀', thinking: '');

    expect(reveal.advance(), isTrue);
    expect(reveal.visibleText, '你');
    expect(reveal.advance(), isTrue);
    expect(reveal.visibleText, '你好');
    expect(reveal.advance(), isTrue);
    expect(reveal.visibleText, '你好呀');
    expect(reveal.isCaughtUp, isTrue);
    expect(reveal.advance(), isFalse);
  });

  test('thinking is revealed before the answer', () {
    final reveal = AiStreamReveal();
    reveal.setTargets(text: '答', thinking: '想');

    reveal.advance();
    expect(reveal.visibleThinking, '想');
    expect(reveal.visibleText, isEmpty);

    reveal.advance();
    expect(reveal.visibleText, '答');
    expect(reveal.isCaughtUp, isTrue);
  });

  test('a burst is paced from the arrival gap', () async {
    final reveal = AiStreamReveal();
    reveal.setTargets(text: 'a', thinking: '');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    reveal.setTargets(text: 'abcdefghij', thinking: '');

    expect(reveal.backlog, 10);
    expect(reveal.nextDelay().inMilliseconds, inInclusiveRange(8, 32));
    reveal.advance();
    expect(reveal.visibleText.length, 1);
  });
}
