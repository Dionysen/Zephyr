import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/plain_text/decoration/decoration_painter.dart';
import 'package:zephyr/ui/features/editor/plain_text/decoration/text_decoration_model.dart';
import 'package:zephyr/ui/features/editor/plain_text/document/plain_text_document.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/editor_typography.dart';
import 'package:zephyr/ui/features/editor/plain_text/layout/plain_text_layout_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decoration ranges resolve to non-empty boxes for selected text', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    engine.update(
      document: const PlainTextDocument('Hello\nWorld'),
      typography: const EditorTypography(
        color: Color(0xFF000000),
        fontSize: 18,
        lineHeight: 1.5,
        paragraphSpacing: 0.5,
        marginLeft: 0,
        marginRight: 0,
        paddingTop: 0,
        paddingBottom: 0,
      ),
      viewportWidth: 400,
    );

    const decoration = TextSpanDecoration(
      start: 0,
      end: 5,
      background: Color(0x33FF0000),
      borderColor: Color(0xFFFF0000),
    );
    final boxes = engine.boxesForRange(decoration.start, decoration.end);
    expect(boxes, isNotEmpty);
    expect(boxes.first.width, greaterThan(0));
  });

  test('highlight boxes hug text and stay centered as line height changes', () {
    Rect decorationBox(double lineHeight) {
      final engine = PlainTextLayoutEngine();
      addTearDown(engine.dispose);
      engine.update(
        document: const PlainTextDocument('Hello'),
        typography: EditorTypography(
          color: const Color(0xFF000000),
          fontSize: 18,
          lineHeight: lineHeight,
          paragraphSpacing: 0,
          marginLeft: 0,
          marginRight: 0,
          paddingTop: 0,
          paddingBottom: 0,
        ),
        viewportWidth: 400,
      );
      final highlight = engine.boxesForRange(0, 5).single;
      final selection = engine
          .boxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 5),
          )
          .single;
      expect(highlight.height, lessThan(selection.height));
      return highlight;
    }

    final compact = decorationBox(1.2);
    final spacious = decorationBox(3);
    expect(spacious.height, closeTo(compact.height, 1));
  });

  test('highlight boxes do not paint the gap between paragraphs', () {
    final engine = PlainTextLayoutEngine();
    addTearDown(engine.dispose);
    engine.update(
      document: const PlainTextDocument('One\nTwo'),
      typography: const EditorTypography(
        color: Color(0xFF000000),
        fontSize: 18,
        lineHeight: 2,
        paragraphSpacing: 1,
        marginLeft: 0,
        marginRight: 0,
        paddingTop: 0,
        paddingBottom: 0,
      ),
      viewportWidth: 400,
    );

    final highlights = engine.boxesForRange(0, 7);
    final selection = engine.boxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
    );
    expect(highlights, hasLength(2));
    expect(selection.length, greaterThan(highlights.length));
    expect(highlights.first.bottom, lessThan(highlights.last.top));
  });

  test('empty paired-punctuation frame stays at glyph height', () async {
    Future<Rect> paintedFrame(double lineHeight) async {
      final engine = PlainTextLayoutEngine();
      addTearDown(engine.dispose);
      engine.update(
        document: const PlainTextDocument('（）'),
        typography: EditorTypography(
          color: const Color(0xFF000000),
          fontSize: 18,
          lineHeight: lineHeight,
          paragraphSpacing: 0,
          marginLeft: 0,
          marginRight: 0,
          paddingTop: 0,
          paddingBottom: 0,
        ),
        viewportWidth: 400,
      );
      final recorder = ui.PictureRecorder();
      paintTextDecorations(
        canvas: Canvas(recorder),
        engine: engine,
        decorations: const [
          TextSpanDecoration(
            start: 1,
            end: 1,
            background: Color(0xFF00FF00),
            borderRadius: 0,
            edgeInflate: EdgeInsets.zero,
            minEmptyWidth: 4,
            emptyAnchorStart: 0,
            emptyAnchorEnd: 2,
          ),
        ],
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 120);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      picture.dispose();
      image.dispose();
      expect(bytes, isNotNull);
      var top = 120;
      var bottom = -1;
      for (var y = 0; y < 120; y++) {
        for (var x = 0; x < 400; x++) {
          if (bytes!.getUint8((y * 400 + x) * 4 + 3) == 0) continue;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
      expect(bottom, greaterThanOrEqualTo(top));
      return Rect.fromLTRB(0, top.toDouble(), 4, (bottom + 1).toDouble());
    }

    final compact = await paintedFrame(1.2);
    final spacious = await paintedFrame(3);
    expect(spacious.height, closeTo(compact.height, 1));
  });
}
