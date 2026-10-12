import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/core/zephyr_resize_handle.dart';

void main() {
  testWidgets('resize updates report displacement from drag start', (
    tester,
  ) async {
    final displacements = <double>[];
    var starts = 0;
    var ends = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 100,
              child: ZephyrResizeHandle(
                onDragStart: () => starts++,
                onDragUpdate: displacements.add,
                onDragEnd: () => ends++,
              ),
            ),
          ),
        ),
      ),
    );

    final origin = tester.getCenter(find.byType(ZephyrResizeHandle));
    final gesture = await tester.startGesture(origin);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(-10, 0));
    await gesture.up();

    expect(starts, 1);
    expect(ends, 1);
    expect(displacements.length, greaterThanOrEqualTo(2));
    expect(displacements.last, displacements[displacements.length - 2] - 10);
    expect(displacements.last, greaterThan(0));
  });
}
