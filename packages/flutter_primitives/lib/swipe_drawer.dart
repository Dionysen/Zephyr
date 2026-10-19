import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Dispatched by descendants (e.g. text selection handles) so the drawer does
/// not claim the same pointer's horizontal drag.
class DrawerDragBlockNotification extends Notification {
  DrawerDragBlockNotification({required this.blocked});
  final bool blocked;
}

/// Blocks a drawer opening swipe while a descendant needs the same gesture.
class DrawerOpenSwipeBlockNotification extends Notification {
  DrawerOpenSwipeBlockNotification({required this.blocked});
  final bool blocked;
}

/// Claims horizontal drags that begin on [child] so a parent
/// [SwipeDrawer] body pan does not open the drawer.
///
/// Use around controls that handle horizontal drags inside the drawer body.
class SwipeDrawerDragShield extends StatelessWidget {
  const SwipeDrawerDragShield({super.key, required this.child});

  final Widget child;

  void _setBlocked(BuildContext context, bool blocked) {
    DrawerDragBlockNotification(blocked: blocked).dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(HorizontalDragGestureRecognizer.new, (
              HorizontalDragGestureRecognizer instance,
            ) {
              instance.onStart = (_) => _setBlocked(context, true);
              instance.onUpdate = (_) {};
              instance.onEnd = (_) => _setBlocked(context, false);
              instance.onCancel = () => _setBlocked(context, false);
            }),
      },
      child: child,
    );
  }
}

/// Full-screen, finger-following start drawer with a low open/close threshold.
///
/// Open: right-swipe on [body] (same as before).
/// Close: left-swipe anywhere once the drawer is visible, including over the
/// panel itself.
class SwipeDrawer extends StatefulWidget {
  const SwipeDrawer({
    super.key,
    required this.body,
    required this.drawer,
    required this.drawerWidth,
    this.enabled = true,
    this.openFraction = 0.18,
    this.minFlingVelocity = 180,
  });

  final Widget body;
  final Widget drawer;
  final double drawerWidth;
  final bool enabled;

  /// Fraction of [drawerWidth] that must be revealed to settle open, and
  /// symmetrically how far it must be dismissed to settle closed.
  final double openFraction;

  /// Horizontal fling speed (px/s) that settles open (positive) or closed.
  final double minFlingVelocity;

  static SwipeDrawerController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SwipeDrawerScope>()
      ?.controller;

  static SwipeDrawerController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No SwipeDrawer ancestor found.');
    return controller!;
  }

  @override
  State<SwipeDrawer> createState() => _SwipeDrawerState();
}

class SwipeDrawerController extends ChangeNotifier {
  _SwipeDrawerState? _state;

  bool get isOpen => _state?._isOpen ?? false;

  void open() => _state?.open();

  void close() => _state?.close();

  void toggle() => isOpen ? close() : open();

  void _emit() => notifyListeners();
}

class _SwipeDrawerScope extends InheritedWidget {
  const _SwipeDrawerScope({required this.controller, required super.child});

  final SwipeDrawerController controller;

  @override
  bool updateShouldNotify(_SwipeDrawerScope oldWidget) =>
      controller != oldWidget.controller;
}

class _SwipeDrawerState extends State<SwipeDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final SwipeDrawerController _controller;
  double _dragStartProgress = 0;

  /// Global X at drag start — pair with [_dragStartProgress] so clamping at
  /// open/closed does not desync the finger from drawer progress.
  double? _dragOriginGlobalX;
  bool _dragBlocked = false;
  bool _openSwipeBlocked = false;
  bool _ignoreActiveDrag = false;

  bool get _isOpen => _progress.value >= 1.0 - 0.001;
  bool get _isVisible => _progress.value > 0;

  @override
  void initState() {
    super.initState();
    _controller = SwipeDrawerController().._state = this;
    _progress =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
          value: 0,
        )..addListener(() {
          _controller._emit();
          setState(() {});
        });
  }

  @override
  void dispose() {
    _controller._state = null;
    _controller.dispose();
    _progress.dispose();
    super.dispose();
  }

  void open() {
    _dismissKeyboard();
    _progress.fling(
      velocity: 2,
      springDescription: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 500,
        ratio: 1.1,
      ),
    );
  }

  void close() {
    _progress.fling(
      velocity: -2,
      springDescription: SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 500,
        ratio: 1.1,
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onDragStart(DragStartDetails details) {
    if (_dragBlocked || _openSwipeBlocked) {
      _ignoreActiveDrag = true;
      return;
    }
    _ignoreActiveDrag = false;
    _progress.stop();
    _dragStartProgress = _progress.value;
    _dragOriginGlobalX = details.globalPosition.dx;
    // Hide the IME as soon as the user starts pulling the drawer open.
    if (_dragStartProgress < 0.05) {
      _dismissKeyboard();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_ignoreActiveDrag || _dragBlocked || _openSwipeBlocked) return;
    final origin = _dragOriginGlobalX;
    if (origin == null) return;
    final dx = details.globalPosition.dx - origin;
    final next = (_dragStartProgress + dx / widget.drawerWidth).clamp(0.0, 1.0);
    _progress.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragOriginGlobalX = null;
    if (_ignoreActiveDrag || _dragBlocked || _openSwipeBlocked) {
      _ignoreActiveDrag = false;
      // Undo any accidental reveal from the same pointer.
      if (!_isOpen && _progress.value > 0) {
        close();
      }
      return;
    }

    final velocity = details.primaryVelocity ?? 0;
    final value = _progress.value;
    final threshold = widget.openFraction;

    if (velocity >= widget.minFlingVelocity) {
      open();
      return;
    }
    if (velocity <= -widget.minFlingVelocity) {
      close();
      return;
    }

    // Short rightward nudge from closed.
    if (_dragStartProgress < 0.05 && value > 0.04) {
      open();
      return;
    }
    // Short leftward nudge from open.
    if (_dragStartProgress > 0.95 && value < 0.96) {
      close();
      return;
    }

    if (_dragStartProgress < 0.5) {
      if (value >= threshold) {
        open();
      } else {
        close();
      }
    } else {
      if (value <= 1.0 - threshold) {
        close();
      } else {
        open();
      }
    }
  }

  void _onDragCancel() {
    _dragOriginGlobalX = null;
    if (_ignoreActiveDrag || _dragBlocked || _openSwipeBlocked) {
      _ignoreActiveDrag = false;
      if (!_isOpen && _progress.value > 0) {
        close();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.drawerWidth;
    final offset = (1.0 - _progress.value) * -width;
    final scrimOpacity = (0.45 * _progress.value).clamp(0.0, 0.45);

    // Open gesture stays on the body only — a permanent full-screen overlay
    // above the content made short open swipes unreliable.
    final body = NotificationListener<DrawerOpenSwipeBlockNotification>(
      onNotification: (notification) {
        _openSwipeBlocked = notification.blocked;
        if (!notification.blocked) {
          _ignoreActiveDrag = false;
        }
        return true;
      },
      child: NotificationListener<DrawerDragBlockNotification>(
        onNotification: (notification) {
          _dragBlocked = notification.blocked;
          if (!notification.blocked) {
            _ignoreActiveDrag = false;
          }
          return true;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: widget.enabled ? _onDragStart : null,
          onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
          onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
          onHorizontalDragCancel: widget.enabled ? _onDragCancel : null,
          child: widget.body,
        ),
      ),
    );

    return _SwipeDrawerScope(
      controller: _controller,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_isOpen) close();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            body,
            if (_isVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: close,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: _onDragCancel,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: scrimOpacity),
                  ),
                ),
              ),
            Positioned(
              left: offset,
              top: 0,
              bottom: 0,
              width: width,
              child: Material(
                elevation: _isVisible ? 8 : 0,
                child: widget.drawer,
              ),
            ),
            // Only while open: full-screen drag so left-swipe works over the
            // drawer panel too. Not mounted when closed, so open stays snappy.
            if (widget.enabled && _isVisible)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: _onDragCancel,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
