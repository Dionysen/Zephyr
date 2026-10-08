import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_window_frame_repository.dart';
import 'package:zephyr/data/services/window_frame_file_storage.dart';
import 'package:zephyr/domain/models/window_frame.dart';

void main() {
  test('round-trips window geometry through app-support storage', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-window-frame-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileWindowFrameRepository(
      WindowFrameFileStorage(directoryProvider: () async => directory),
    );

    await repository.save(
      const WindowFrame(
        width: 1440,
        height: 900,
        x: 120,
        y: 80,
        maximized: true,
      ),
    );
    final actual = await repository.load();

    expect(actual.width, 1440);
    expect(actual.height, 900);
    expect(actual.x, 120);
    expect(actual.y, 80);
    expect(actual.maximized, isTrue);
  });

  test('missing file returns defaults', () async {
    final directory = await Directory.systemTemp.createTemp(
      'zephyr-window-frame-empty-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = FileWindowFrameRepository(
      WindowFrameFileStorage(directoryProvider: () async => directory),
    );

    final actual = await repository.load();

    expect(actual, WindowFrame.defaults);
    expect(actual.hasPosition, isFalse);
  });
}
