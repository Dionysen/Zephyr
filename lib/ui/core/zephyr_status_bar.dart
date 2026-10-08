import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Transparent system status bar; icon/text color follows theme brightness.
class ZephyrStatusBar extends StatelessWidget {
  const ZephyrStatusBar({
    super.key,
    required this.child,
    this.brightness,
  });

  final Widget child;

  /// When null, uses [ThemeData.brightness] from context.
  final Brightness? brightness;

  /// Overlay style with a transparent status bar for [brightness].
  static SystemUiOverlayStyle styleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved =
        brightness ?? Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: styleFor(resolved),
      child: child,
    );
  }
}
