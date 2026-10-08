import 'dart:io';

/// Cross-platform icon pipeline for Windows / macOS / Linux (and CI).
///
/// Usage (same on every desktop):
///   dart run tool/generate_app_icons.dart
///   dart run tool/generate_app_icons.dart --skip-svg
///
/// 1. Rasterizes branding/app_icon.svg → branding/app_icon.png via Flutter
///    (no ImageMagick / Inkscape / rsvg required)
/// 2. Runs flutter_launcher_icons for all configured platforms
Future<void> main(List<String> args) async {
  final skipSvg = args.contains('--skip-svg');
  Directory.current = _projectRoot();

  if (!skipSvg) {
    if (!File('branding/app_icon.svg').existsSync()) {
      stderr.writeln('Missing master icon: branding/app_icon.svg');
      exitCode = 1;
      return;
    }
    stdout.writeln(
      'Rasterizing branding/app_icon.svg -> '
      'app_icon.png (iOS corners) + app_icon_square.png',
    );
    final code = await _run('flutter', [
      'test',
      'tool/rasterize_app_icon_test.dart',
      '--reporter',
      'compact',
    ]);
    if (code != 0) {
      exitCode = code;
      return;
    }
  } else if (!File('branding/app_icon.png').existsSync()) {
    stderr.writeln(
      'Missing branding/app_icon.png (required with --skip-svg)',
    );
    exitCode = 1;
    return;
  }

  if (!File('branding/app_icon.png').existsSync()) {
    stderr.writeln('Expected branding/app_icon.png after conversion.');
    exitCode = 1;
    return;
  }

  stdout.writeln('Running flutter_launcher_icons...');
  final icons = await _run('dart', ['run', 'flutter_launcher_icons']);
  if (icons != 0) {
    exitCode = icons;
    return;
  }

  stdout.writeln('Done. Rebuild the app to pick up the new icons.');
}

Directory _projectRoot() {
  final script = File(Platform.script.toFilePath());
  return script.parent.parent;
}

Future<int> _run(String executable, List<String> arguments) async {
  final process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  return process.exitCode;
}
