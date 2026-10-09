import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/status_bar_mode.dart';

/// Top inset that stays reserved even when immersive mode zeroed [padding].
double zephyrTopInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).top;

/// Applies [StatusBarMode] and wraps [child] with the matching overlay style.
class ZephyrStatusBar extends StatefulWidget {
  const ZephyrStatusBar({
    super.key,
    required this.child,
    this.mode = StatusBarMode.transparent,
    this.statusBarColor,
    this.brightness,
  });

  final Widget child;
  final StatusBarMode mode;

  /// Used when [mode] is [StatusBarMode.normal]; falls back to theme surface.
  final Color? statusBarColor;

  /// When null, uses [ThemeData.brightness] from context.
  final Brightness? brightness;

  static SystemUiOverlayStyle styleFor(
    Brightness brightness, {
    StatusBarMode mode = StatusBarMode.transparent,
    Color? statusBarColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final color = mode == StatusBarMode.normal
        ? (statusBarColor ?? Colors.black)
        : Colors.transparent;
    return SystemUiOverlayStyle(
      statusBarColor: color,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
    );
  }

  static Future<void> applySystemUiMode(StatusBarMode mode) async {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        break;
      case _:
        return;
    }
    switch (mode) {
      case StatusBarMode.immersive:
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      case StatusBarMode.normal:
      case StatusBarMode.transparent:
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  State<ZephyrStatusBar> createState() => _ZephyrStatusBarState();
}

class _ZephyrStatusBarState extends State<ZephyrStatusBar> {
  StatusBarMode? _appliedMode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSystemUi();
  }

  @override
  void didUpdateWidget(covariant ZephyrStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _syncSystemUi();
    }
  }

  void _syncSystemUi() {
    if (_appliedMode == widget.mode) return;
    _appliedMode = widget.mode;
    // ignore: discarded_futures
    ZephyrStatusBar.applySystemUiMode(widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.brightness ?? Theme.of(context).brightness;
    final surface =
        widget.statusBarColor ?? Theme.of(context).colorScheme.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ZephyrStatusBar.styleFor(
        resolved,
        mode: widget.mode,
        statusBarColor: surface,
      ),
      child: widget.child,
    );
  }
}

/// Pads [child] using view/padding insets. Top uses [zephyrTopInset] so the
/// reserved band survives immersive mode when [top] is true.
class ZephyrTopSafeArea extends StatelessWidget {
  const ZephyrTopSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.left = true,
    this.right = true,
    this.bottom = true,
  });

  final Widget child;
  final bool top;
  final bool left;
  final bool right;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        top: top ? viewPadding.top : 0,
        left: left ? padding.left : 0,
        right: right ? padding.right : 0,
        bottom: bottom ? padding.bottom : 0,
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: top,
        removeLeft: left,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }
}
