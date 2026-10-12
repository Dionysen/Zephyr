import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/ui/features/editor/quick_toolbar/tools_panel_toggle_gate.dart';

void main() {
  testWidgets('two rapid taps cancel the pending drawer change', (
    tester,
  ) async {
    var open = false;
    final commits = <bool>[];
    final gate = ToolsPanelToggleGate(
      isDrawerOpen: () => open,
      onCommit: (value) {
        open = value;
        commits.add(value);
      },
      actionDelay: const Duration(milliseconds: 20),
    );
    addTearDown(gate.dispose);

    gate.toggle();
    expect(gate.pendingOpen, isTrue);
    gate.toggle();
    expect(gate.pendingOpen, isFalse);
    await tester.pump(const Duration(milliseconds: 21));

    expect(open, isFalse);
    expect(commits, isEmpty);
    expect(gate.pendingOpen, isNull);
  });

  testWidgets(
    'queued intent commits after the current IME transition settles',
    (tester) async {
      var open = false;
      final commits = <bool>[];
      final gate = ToolsPanelToggleGate(
        isDrawerOpen: () => open,
        onCommit: (value) {
          open = value;
          commits.add(value);
        },
        actionDelay: const Duration(milliseconds: 20),
      );
      addTearDown(gate.dispose);

      gate.toggle();
      await tester.pump(const Duration(milliseconds: 21));
      expect(gate.isBusy, isTrue);
      expect(commits, [true]);

      gate.toggle();
      await tester.pump(const Duration(milliseconds: 21));
      expect(commits, [true]);

      gate.markSettled();
      expect(commits, [true, false]);
      expect(gate.isBusy, isTrue);
      gate.markSettled();
      expect(gate.isBusy, isFalse);
    },
  );

  testWidgets(
    'close cancels a pending open and busy timeout unlocks the gate',
    (tester) async {
      var open = false;
      final commits = <bool>[];
      final gate = ToolsPanelToggleGate(
        isDrawerOpen: () => open,
        onCommit: (value) {
          open = value;
          commits.add(value);
        },
        actionDelay: const Duration(milliseconds: 20),
        busyTimeout: const Duration(milliseconds: 30),
      );
      addTearDown(gate.dispose);

      gate.toggle();
      gate.close();
      await tester.pump(const Duration(milliseconds: 21));
      expect(commits, isEmpty);

      gate.toggle();
      await tester.pump(const Duration(milliseconds: 21));
      expect(gate.isBusy, isTrue);
      await tester.pump(const Duration(milliseconds: 31));
      expect(gate.isBusy, isFalse);
      expect(commits, [true]);
    },
  );
}
