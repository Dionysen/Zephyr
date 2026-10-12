import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/core/breakpoints.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_selection.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';

void main() {
  test('selection clamps both ends while preserving reversed direction', () {
    const selection = TextSelection(baseOffset: 12, extentOffset: -1);

    final clamped = selection.clampedTo(8);

    expect(clamped.baseOffset, 8);
    expect(clamped.extentOffset, 0);
    expect(clampOffset(-3, 8), 0);
    expect(clampOffset(12, 8), 8);
  });

  test('selection extension keeps its anchor only when selecting', () {
    const selection = TextSelection(baseOffset: 2, extentOffset: 5);

    final extended = selection.withExtentAt(7, selecting: true);
    final moved = selection.withExtentAt(7, selecting: false);

    expect(extended.baseOffset, 2);
    expect(extended.extentOffset, 7);
    expect(moved.isCollapsed, isTrue);
    expect(moved.baseOffset, 7);
  });

  test(
    'typography copies reading style and can clear optional font and width',
    () {
      const typography = EditorTypography(
        color: Color(0xFF112233),
        fontSize: 20,
        fontFamily: 'Imported',
        lineHeight: 1.5,
        paragraphSpacing: 0.5,
        marginLeft: 24,
        marginRight: 24,
        centeredContentWidth: 720,
      );

      expect(typography.paragraphGap, 10);
      expect(typography.textStyle.fontSize, 20);
      expect(typography.strutStyle.forceStrutHeight, isTrue);
      final cleared = typography.copyWith(
        clearFontFamily: true,
        clearCenteredContentWidth: true,
      );
      expect(cleared.fontFamily, isNull);
      expect(cleared.centeredContentWidth, isNull);
      expect(cleared.paragraphGap, typography.paragraphGap);
      expect(cleared, isNot(typography));
    },
  );

  test('compact layout ends exactly at the shared breakpoint', () {
    expect(ZephyrBreakpoints.isCompact(ZephyrBreakpoints.compact - 1), isTrue);
    expect(ZephyrBreakpoints.isCompact(ZephyrBreakpoints.compact), isFalse);
  });
}
