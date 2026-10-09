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
    this.hideIcons = true,
    this.statusBarColor,
    this.brightness,
  });

  final Widget child;

  /// When true, the shell may draw under the transparent status band.
  final bool immersive;

  /// When [immersive] is true and this is true, status icons auto-hide.
  final bool hideIcons;

  /// Surface color behind the status band (for themed shells).
  final Color? statusBarColor;

  /// When null, uses [ThemeData.brightness] from context.
  final Brightness? brightness;

  static SystemUiOverlayStyle styleFor(
    Brightness brightness, {
    bool immersive = false,
    bool hideIcons = true,
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

  static Future<void> applySystemUiMode({
    required bool immersive,
    required bool hideIcons,
  }) async {
    if (!_isMobileShell) return;
    if (immersive && hideIcons) {
      // Auto-hide icons; swipe edge to peek. App still paints under the band.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  State<ZephyrStatusBar> createState() => _ZephyrStatusBarState();
}

class _ZephyrStatusBarState extends State<ZephyrStatusBar> {
  bool? _appliedImmersive;
  bool? _appliedHideIcons;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSystemUi();
  }

  @override
  void didUpdateWidget(covariant ZephyrStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immersive != widget.immersive ||
        oldWidget.hideIcons != widget.hideIcons) {
      _syncSystemUi();
    }
  }

  void _syncSystemUi() {
    if (_appliedImmersive == widget.immersive &&
        _appliedHideIcons == widget.hideIcons) {
      return;
    }
    _appliedImmersive = widget.immersive;
    _appliedHideIcons = widget.hideIcons;
    // ignore: discarded_futures
    ZephyrStatusBar.applySystemUiMode(
      immersive: widget.immersive,
      hideIcons: widget.hideIcons,
    );
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
        hideIcons: widget.hideIcons,
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
