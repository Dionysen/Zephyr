import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/core/zephyr_dual_editor_pager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keeps both editors visible while crossing between books', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final activeEditors = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: ZephyrDualEditorPager(
            drawerWidth: 320,
            onActiveEditorChanged: activeEditors.add,
            fixedOverlay: Container(
              key: const ValueKey('fixed-top-bar'),
              height: 48,
              color: Colors.white,
            ),
            startDrawer: Container(
              key: const ValueKey('start-drawer'),
              color: Colors.red,
              child: const Center(child: Text('Left library')),
            ),
            primaryEditor: Container(
              key: const ValueKey('primary-editor'),
              color: Colors.blue,
              child: const Center(child: Text('Left editor')),
            ),
            companionEditor: Container(
              key: const ValueKey('companion-editor'),
              color: Colors.green,
              child: const Center(child: Text('Right editor')),
            ),
            endDrawer: Container(
              key: const ValueKey('end-drawer'),
              color: Colors.orange,
              child: const Center(child: Text('Right library')),
            ),
          ),
        ),
      ),
    );

    final topBarStart = tester.getRect(
      find.byKey(const ValueKey('fixed-top-bar')),
    );
    final drag = await tester.startGesture(const Offset(200, 350));
    await drag.moveBy(const Offset(-220, 0));
    await tester.pump();

    final leftRect = tester.getRect(
      find.byKey(const ValueKey('primary-editor')),
    );
    final rightRect = tester.getRect(
      find.byKey(const ValueKey('companion-editor')),
    );
    final topBarRect = tester.getRect(
      find.byKey(const ValueKey('fixed-top-bar')),
    );
    expect(leftRect.right, greaterThan(0));
    expect(rightRect.left, lessThan(400));
    expect(topBarRect, topBarStart);

    await drag.up();
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('companion-editor'))).dx,
      closeTo(0, 1),
    );
    expect(activeEditors, contains(1));
  });

  testWidgets('opens the right library after the companion editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: ZephyrDualEditorPager(
            drawerWidth: 320,
            startDrawer: const Center(child: Text('Left library')),
            primaryEditor: const Center(child: Text('Left editor')),
            companionEditor: const Center(child: Text('Right editor')),
            endDrawer: Container(
              key: const ValueKey('end-drawer'),
              child: const Center(child: Text('Right library')),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Left editor'), const Offset(-260, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Right editor'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('end-drawer'))).left,
      closeTo(80, 1),
    );
  });

  testWidgets('opens and closes a library after short outward swipes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 700,
          child: ZephyrDualEditorPager(
            drawerWidth: 320,
            startDrawer: Container(key: const ValueKey('start-drawer')),
            primaryEditor: const Center(child: Text('Left editor')),
            companionEditor: const Center(child: Text('Right editor')),
            endDrawer: const SizedBox(),
          ),
        ),
      ),
    );

    final drag = await tester.startGesture(const Offset(200, 350));
    await drag.moveBy(const Offset(24, 0));
    await drag.up();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('start-drawer'))).left,
      closeTo(0, 1),
    );

    final closeDrag = await tester.startGesture(const Offset(200, 350));
    await closeDrag.moveBy(const Offset(-24, 0));
    await closeDrag.up();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('start-drawer'))).right,
      closeTo(0, 1),
    );
  });
}
