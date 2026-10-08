import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../domain/models/window_frame.dart';
import '../../domain/repositories/window_frame_repository.dart';
import 'zephyr_controls.dart';

/// Isolates desktop window dragging and caption buttons from feature widgets.
abstract final class WindowChrome {
  static bool get isDesktop {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get usesCaptionButtons => isDesktop && Platform.isWindows;

  static bool get usesMacOSTrafficLights => isDesktop && Platform.isMacOS;

  /// Fallback until [syncNativeMetrics] reads the real traffic-light frames.
  static const macOSTrafficLightInset = 80.0;

  /// Matches the vertical inset of a [ZephyrControls.buttonSize] control
  /// centered in [titleBarHeight] on Windows: (36 - 28) / 2.
  static const windowsLeadingInset = 4.0;

  static double _macOSLeadingInset = macOSTrafficLightInset;
  static double _macOSTitleBarHeight = ZephyrControls.buttonSize;

  static double get leadingChromeInset {
    if (usesMacOSTrafficLights) return _macOSLeadingInset;
    if (isDesktop && Platform.isWindows) return windowsLeadingInset;
    return 0;
  }

  /// On macOS this is tall enough that a [ZephyrControls.buttonSize] control
  /// can share a vertical center with the native traffic lights.
  static double get titleBarHeight =>
      usesMacOSTrafficLights ? _macOSTitleBarHeight : 36;

  static Future<void> syncNativeMetrics() async {
    if (!usesMacOSTrafficLights) {
      return;
    }
    try {
      const channel = MethodChannel('zephyr/window_chrome');
      final metrics = await channel.invokeMapMethod<String, dynamic>('metrics');
      if (metrics == null) {
        return;
      }
      final centerY = (metrics['centerY'] as num?)?.toDouble();
      final leading = (metrics['leading'] as num?)?.toDouble();
      if (centerY != null && centerY > 0) {
        _macOSTitleBarHeight = math.max(ZephyrControls.buttonSize, centerY * 2);
      }
      if (leading != null && leading > 0) {
        _macOSLeadingInset = leading;
      }
    } on Object {
      // Native chrome is optional when the embedder has no method channel.
    }
  }
}

class WindowDragArea extends StatelessWidget {
  const WindowDragArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!WindowChrome.isDesktop) {
      return child;
    }
    return DragToMoveArea(child: child);
  }
}

/// Keeps the native window backdrop aligned with the writing-shell theme.
class DesktopWindowBackdrop extends StatefulWidget {
  const DesktopWindowBackdrop({
    super.key,
    required this.color,
    required this.child,
  });

  final Color color;
  final Widget child;

  @override
  State<DesktopWindowBackdrop> createState() => _DesktopWindowBackdropState();
}

class _DesktopWindowBackdropState extends State<DesktopWindowBackdrop> {
  @override
  void initState() {
    super.initState();
    unawaited(_sync());
  }

  @override
  void didUpdateWidget(covariant DesktopWindowBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      unawaited(_sync());
    }
  }

  Future<void> _sync() async {
    if (!WindowChrome.isDesktop) {
      return;
    }
    try {
      await windowManager.setBackgroundColor(widget.color);
    } on Object {
      // Native chrome is optional when plugins are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class WindowCaptionButtons extends StatelessWidget {
  const WindowCaptionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    if (!WindowChrome.usesCaptionButtons) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return SizedBox(
      width: 138,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

/// Restores and persists desktop window size/position across launches.
class WindowFrameTracker with WindowListener {
  WindowFrameTracker(this._repository, {WindowFrame? initial})
    : _normalFrame = clamp(
        (initial ?? WindowFrame.defaults).copyWith(maximized: false),
      );

  /// Keeps the active tracker reachable for the process lifetime.
  static WindowFrameTracker? active;

  final WindowFrameRepository _repository;
  Timer? _debounce;
  WindowFrame _normalFrame;
  var _closing = false;

  static WindowFrame clamp(WindowFrame frame) {
    final min = ZephyrControls.minWindowSize;
    return frame.copyWith(
      width: math.max(frame.width, min.width),
      height: math.max(frame.height, min.height),
    );
  }

  static Future<void> apply(WindowFrame frame) async {
    final clamped = clamp(frame);
    await windowManager.setBounds(
      Rect.fromLTWH(
        clamped.x ?? 0,
        clamped.y ?? 0,
        clamped.width,
        clamped.height,
      ),
    );
    if (clamped.maximized) {
      await windowManager.maximize();
    }
  }

  Future<void> start() async {
    if (!WindowChrome.isDesktop) {
      return;
    }
    active = this;
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();

  @override
  void onWindowClose() {
    if (_closing) {
      return;
    }
    _closing = true;
    unawaited(_close());
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_persist());
    });
  }

  Future<void> _close() async {
    _debounce?.cancel();
    await _persist();
    try {
      await windowManager.destroy();
    } on Object {
      // Native close is best-effort once the frame is persisted.
    }
  }

  Future<void> _persist() async {
    if (!WindowChrome.isDesktop) {
      return;
    }
    try {
      final maximized = await windowManager.isMaximized();
      final bounds = await windowManager.getBounds();
      if (!maximized) {
        _normalFrame = clamp(
          WindowFrame(
            width: bounds.width,
            height: bounds.height,
            x: bounds.left,
            y: bounds.top,
          ),
        );
        await _repository.save(_normalFrame);
        return;
      }
      await _repository.save(_normalFrame.copyWith(maximized: true));
    } on Object {
      // Geometry persistence must never block quitting.
    }
  }
}
