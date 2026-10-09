import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Top inset that stays reserved for chrome even when the app draws edge-to-edge.
double zephyrTopInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).top;

bool get _isMobileShell {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

/// Transparent system status bar. The app always draws edge-to-edge on mobile;
/// [immersive] only changes whether chrome/content may use the status band.
class ZephyrStatusBar extends StatefulWidget {
  const ZephyrStatusBar({
    super.key,
    required this.child,
    this.immersive = false,
    this.statusBarColor,
    this.brightness,
  });

  final Widget child;

  /// Layout hint for shells (extend under the status band). System UI stays
  /// edge-to-edge + transparent either way so the app shows through the bar.
  final bool immersive;

  /// Surface color behind the status band (for themed shells).
  final Color? statusBarColor;

  /// When null, uses [ThemeData.brightness] from context.
  final Brightness? brightness;

  static SystemUiOverlayStyle styleFor(
    Brightness brightness, {
    bool immersive = false,
    Color? statusBarColor,
  }) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
    );
  }

  static Future<void> applySystemUiMode({required bool immersive}) async {
    if (!_isMobileShell) return;
    // Always edge-to-edge so a transparent status bar reveals the app surface.
    // Immersive is a layout concern (draw under / scroll under), not sticky hide.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  State<ZephyrStatusBar> createState() => _ZephyrStatusBarState();
}

class _ZephyrStatusBarState extends State<ZephyrStatusBar> {
  var _appliedEdgeToEdge = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSystemUi();
  }

  @override
  void didUpdateWidget(covariant ZephyrStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immersive != widget.immersive) {
      _syncSystemUi(force: true);
    }
  }

  void _syncSystemUi({bool force = false}) {
    if (_appliedEdgeToEdge && !force) return;
    _appliedEdgeToEdge = true;
    // ignore: discarded_futures
    ZephyrStatusBar.applySystemUiMode(immersive: widget.immersive);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = widget.brightness ?? Theme.of(context).brightness;
    final surface =
        widget.statusBarColor ?? Theme.of(context).colorScheme.surface;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ZephyrStatusBar.styleFor(
        resolved,
        immersive: widget.immersive,
        statusBarColor: surface,
      ),
      child: widget.child,
    );
  }
}

/// Pads [child] using view/padding insets. Prefer wrapping *inside* a painted
/// surface so the parent color still fills the status-bar band.
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
