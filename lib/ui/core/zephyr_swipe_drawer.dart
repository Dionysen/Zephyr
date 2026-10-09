import 'package:flutter/material.dart';

/// Dispatched by descendants (e.g. text selection handles) so the drawer does
/// not claim the same pointer's horizontal drag.
class ZephyrDrawerDragBlockNotification extends Notification {
  ZephyrDrawerDragBlockNotification({required this.blocked});
  final bool blocked;
}

/// Full-screen, finger-following start drawer with a low open/close threshold.
///
/// Open: right-swipe on [body] (same as before).
/// Close: left-swipe anywhere once the drawer is visible, including over the
/// panel itself.
class ZephyrSwipeDrawer extends StatefulWidget {
  const ZephyrSwipeDrawer({
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

  static ZephyrSwipeDrawerController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ZephyrSwipeDrawerScope>()
          ?.controller;

  static ZephyrSwipeDrawerController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No ZephyrSwipeDrawer ancestor found.');
    return controller!;
  }

  @override
  State<ZephyrSwipeDrawer> createState() => _ZephyrSwipeDrawerState();
}

class ZephyrSwipeDrawerController extends ChangeNotifier {
  _ZephyrSwipeDrawerState? _state;

  bool get isOpen => _state?._isOpen ?? false;

  void open() => _state?.open();

  void close() => _state?.close();

  void toggle() => isOpen ? close() : open();

  void _emit() => notifyListeners();
}

class _ZephyrSwipeDrawerScope extends InheritedWidget {
  const _ZephyrSwipeDrawerScope({
    required this.controller,
    required super.child,
  });

  final ZephyrSwipeDrawerController controller;

  @override
  bool updateShouldNotify(_ZephyrSwipeDrawerScope oldWidget) =>
      controller != oldWidget.controller;
}

class _ZephyrSwipeDrawerState extends State<ZephyrSwipeDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  late final ZephyrSwipeDrawerController _controller;
  double _dragStartProgress = 0;
  bool _dragBlocked = false;
  bool _ignoreActiveDrag = false;

  bool get _isOpen => _progress.value >= 1.0 - 0.001;
  bool get _isVisible => _progress.value > 0;

  @override
  void initState() {
    super.initState();
    _controller = ZephyrSwipeDrawerController().._state = this;
    _progress = AnimationController(
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
    if (_dragBlocked) {
      _ignoreActiveDrag = true;
      return;
    }
    _ignoreActiveDrag = false;
    _progress.stop();
    _dragStartProgress = _progress.value;
    // Hide the IME as soon as the user starts pulling the drawer open.
    if (_dragStartProgress < 0.05) {
      _dismissKeyboard();
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_ignoreActiveDrag || _dragBlocked) return;
    final delta = details.primaryDelta ?? 0;
    if (delta == 0) return;
    final next = (_progress.value + delta / widget.drawerWidth).clamp(0.0, 1.0);
    _progress.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_ignoreActiveDrag || _dragBlocked) {
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
    if (_ignoreActiveDrag || _dragBlocked) {
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
    // above the editor made short open swipes unreliable.
    final body = NotificationListener<ZephyrDrawerDragBlockNotification>(
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
    );

    return _ZephyrSwipeDrawerScope(
      controller: _controller,
      child: PopScope(
        canPop: !_isOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _isOpen) close();
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
