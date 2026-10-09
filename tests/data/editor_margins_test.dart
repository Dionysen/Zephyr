import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/editor_margins.dart';

void main() {
  test('keeps equal margins identical after proportional shrink', () {
    final margins = EditorMargins.resolve(
      viewportWidth: 300,
      desiredLeft: 100,
      desiredRight: 100,
      minContentWidth: 200,
    );
    expect(margins.left, margins.right);
    expect(margins.left, 50);
    expect(margins.contentWidth, 200);
  });

  test('preserves 2:1 ratio when shrinking', () {
    final margins = EditorMargins.resolve(
      viewportWidth: 300,
      desiredLeft: 100,
      desiredRight: 50,
      minContentWidth: 200,
    );
    expect(margins.left, closeTo(200 / 3, 1e-9));
    expect(margins.right, closeTo(100 / 3, 1e-9));
  });

  test('uses exact preferences when they fit', () {
    final margins = EditorMargins.resolve(
      viewportWidth: 400,
      desiredLeft: 24,
      desiredRight: 48,
      minContentWidth: 120,
    );
    expect(margins.left, 24);
    expect(margins.right, 48);
    expect(margins.contentWidth, 328);
  });
}
