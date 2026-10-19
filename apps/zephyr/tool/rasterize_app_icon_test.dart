import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ios_app_icon_mask.dart';

/// Rasterizes [branding/app_icon.svg] to PNGs at 1024×1024.
///
/// - [branding/app_icon.png] — iOS continuous-corner mask (desktop / branding)
/// - [branding/app_icon_square.png] — full-bleed square (iOS / Android adaptive)
///
/// Invoked by `dart run tool/generate_app_icons.dart` — not part of the normal
/// `flutter test` suite (that only runs `test/`).
void main() {
  test('rasterize branding/app_icon.svg to PNG', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final svgFile = File('branding/app_icon.svg');
    final roundedFile = File('branding/app_icon.png');
    final squareFile = File('branding/app_icon_square.png');
    expect(
      svgFile.existsSync(),
      isTrue,
      reason: 'Missing master icon: branding/app_icon.svg',
    );

    const size = 1024;
    final pictureInfo = await vg.loadPicture(SvgFileLoader(svgFile), null);
    final src = pictureInfo.size;

    Future<void> writePng(File file, {required bool roundCorners}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      if (roundCorners) {
        canvas.clipPath(iosAppIconMask(size.toDouble()));
      }
      canvas.scale(size / src.width, size / src.height);
      canvas.drawPicture(pictureInfo.picture);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size, size);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
      image.dispose();
    }

    await writePng(squareFile, roundCorners: false);
    await writePng(roundedFile, roundCorners: true);

    pictureInfo.picture.dispose();
  });
}
