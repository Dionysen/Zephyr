import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Isolates desktop window dragging and caption buttons from feature widgets.
abstract final class WindowChrome {
  static bool get isDesktop {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get usesCaptionButtons => isDesktop && Platform.isWindows;
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
