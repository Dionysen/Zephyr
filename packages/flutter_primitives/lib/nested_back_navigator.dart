import 'package:flutter/material.dart';

/// Nested [Navigator] that receives system / gesture back before its host.
///
/// When the nested stack can pop, back pops that route (sub-page, sheet, …).
/// When it cannot:
/// - if [onExit] is set, that callback runs (e.g. close a settings panel);
/// - otherwise the enclosing route is allowed to pop normally.
class NestedBackNavigator extends StatefulWidget {
  const NestedBackNavigator({
    super.key,
    required this.onGenerateRoute,
    this.initialRoute = Navigator.defaultRouteName,
    this.onExit,
  });

  final RouteFactory onGenerateRoute;
  final String initialRoute;

  /// Invoked when back is pressed and the nested stack cannot pop.
  ///
  /// When non-null, the enclosing route is never popped by this widget.
  final VoidCallback? onExit;

  @override
  State<NestedBackNavigator> createState() => _NestedBackNavigatorState();
}

class _NestedBackNavigatorState extends State<NestedBackNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final NavigatorObserver _observer = _NestedNavigatorObserver(() {
    // didPush can fire while the nested Navigator is still mounting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  });

  bool get _nestedCanPop => _navigatorKey.currentState?.canPop() ?? false;

  @override
  Widget build(BuildContext context) {
    final intercept = _nestedCanPop || widget.onExit != null;
    return PopScope(
      canPop: !intercept,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        final nav = _navigatorKey.currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
          return;
        }
        widget.onExit?.call();
      },
      child: Navigator(
        key: _navigatorKey,
        initialRoute: widget.initialRoute,
        onGenerateRoute: widget.onGenerateRoute,
        observers: [_observer],
      ),
    );
  }
}

class _NestedNavigatorObserver extends NavigatorObserver {
  _NestedNavigatorObserver(this.onStackChanged);

  final VoidCallback onStackChanged;

  void _notify() => onStackChanged();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _notify();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _notify();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _notify();
}
