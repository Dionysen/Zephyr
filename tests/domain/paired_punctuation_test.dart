import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/use_cases/paired_punctuation.dart';

void main() {
  test('single opener expands to a full pair', () {
    expect(resolvePairedPunctuationInsert('“')?.text, '“”');
    expect(resolvePairedPunctuationInsert('《')?.text, '《》');
    expect(resolvePairedPunctuationInsert('（')?.text, '（）');
    expect(resolvePairedPunctuationInsert('(')?.text, '()');
    expect(resolvePairedPunctuationInsert('"')?.text, '""');
  });

  test('full pair payload is accepted as-is', () {
    expect(resolvePairedPunctuationInsert('“”')?.text, '“”');
    expect(resolvePairedPunctuationInsert('「」')?.text, '「」');
    expect(resolvePairedPunctuationInsert('（）')?.text, '（）');
  });

  test('non-pair phrases are ignored', () {
    expect(resolvePairedPunctuationInsert('署名'), isNull);
    expect(resolvePairedPunctuationInsert('……'), isNull);
    expect(resolvePairedPunctuationInsert(''), isNull);
  });

  test('remap keeps anchors when typing between the pair', () {
    const before = 'A“”B';
    const after = 'A“x”B';
    final session = PairedPunctuationSession(
      openIndex: 1,
      closeIndex: 2,
      openChar: '“',
      closeChar: '”',
    );
    final next = remapPairedPunctuationSession(session, before, after);
    expect(next, isNotNull);
    expect(next!.openIndex, 1);
    expect(next.closeIndex, 3);
    expect(next.matches(after), isTrue);
  });

  test('remap clears when an anchor is deleted', () {
    const before = 'A“”B';
    const after = 'A”B';
    final session = PairedPunctuationSession(
      openIndex: 1,
      closeIndex: 2,
      openChar: '“',
      closeChar: '”',
    );
    expect(remapPairedPunctuationSession(session, before, after), isNull);
  });

  test('empty pair opener delete yields orphan closer range', () {
    const before = 'A“”B';
    const after = 'A”B';
    final session = PairedPunctuationSession(
      openIndex: 1,
      closeIndex: 2,
      openChar: '“',
      closeChar: '”',
    );
    expect(session.isEmptyInterior, isTrue);
    final orphan = orphanCloserRangeAfterEmptyOpenDeleted(
      session: session,
      before: before,
      after: after,
    );
    expect(orphan, isNotNull);
    expect(orphan!.start, 1);
    expect(orphan.end, 2);
  });

  test('non-empty pair opener delete does not yield orphan cleanup', () {
    const before = 'A“x”B';
    const after = 'Ax”B';
    final session = PairedPunctuationSession(
      openIndex: 1,
      closeIndex: 3,
      openChar: '“',
      closeChar: '”',
    );
    expect(session.isEmptyInterior, isFalse);
    expect(
      orphanCloserRangeAfterEmptyOpenDeleted(
        session: session,
        before: before,
        after: after,
      ),
      isNull,
    );
  });

  test('detects typed single opener for auto-pair', () {
    final typed = detectTypedPairedPunctuation(before: 'A', after: 'A“');
    expect(typed, isNotNull);
    expect(typed!.needsCloser, isTrue);
    expect(typed.openIndex, 1);
    expect(typed.pair.text, '“”');
  });

  test('detects typed full pair without needing closer', () {
    final typed = detectTypedPairedPunctuation(before: 'A', after: 'A“”');
    expect(typed, isNotNull);
    expect(typed!.needsCloser, isFalse);
    expect(typed.openIndex, 1);
    expect(typed.pair.isVisuallyNarrow, isTrue);
  });

  test('detects composing commit of a full pair', () {
    final typed = detectTypedPairedPunctuation(before: 'A\u200b', after: 'A“”');
    expect(typed, isNotNull);
    expect(typed!.needsCloser, isFalse);
    expect(typed.openIndex, 1);
  });

  test('distinguishes lone opener from full pair', () {
    final opener = detectTypedPairedPunctuation(before: '', after: '“');
    expect(opener!.needsCloser, isTrue);
    final full = detectTypedPairedPunctuation(before: '', after: '“”');
    expect(full!.needsCloser, isFalse);
  });

  test('redundant closer insert is detected inside an empty pair', () {
    expect(
      isRedundantPairedCloserInsert(text: 'A“”B', offset: 2, closer: '”'),
      isTrue,
    );
    expect(
      isRedundantPairedCloserInsert(text: 'A“”B', offset: 3, closer: '”'),
      isTrue,
    );
    expect(
      isRedundantPairedCloserInsert(text: 'A“x”B', offset: 3, closer: '”'),
      isFalse,
    );
  });

  test('ignores non-pair typing', () {
    expect(detectTypedPairedPunctuation(before: 'A', after: 'Ax'), isNull);
  });

  test('containsSelection is only true between the pair glyphs', () {
    final session = PairedPunctuationSession(
      openIndex: 1,
      closeIndex: 2,
      openChar: '“',
      closeChar: '”',
    );
    expect(
      session.containsSelection(const TextSelection.collapsed(offset: 2)),
      isTrue,
    );
    expect(
      session.containsSelection(const TextSelection.collapsed(offset: 1)),
      isFalse,
    );
    expect(
      session.containsSelection(const TextSelection.collapsed(offset: 3)),
      isFalse,
    );
  });
}
