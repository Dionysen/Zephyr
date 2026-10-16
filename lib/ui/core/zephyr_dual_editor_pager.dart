import 'package:flutter/material.dart';

import 'zephyr_swipe_drawer.dart';

/// A compact, continuous writing surface: start drawer, two editor pages, and
/// end drawer. The editor pages share one horizontal drag space, so both stay
/// visible while crossing between books.
class ZephyrDualEditorPager extends StatefulWidget {
  const ZephyrDualEditorPager({
    super.key,
    required this.startDrawer,
    required this.primaryEditor,
    required this.companionEditor,
    required this.endDrawer,
    required this.drawerWidth,
    this.onActiveEditorChanged,
    this.fixedOverlay,
  });

  final Widget startDrawer;
  final Widget primaryEditor;
  final Widget companionEditor;
  final Widget endDrawer;
  final double drawerWidth;
  final ValueChanged<int>? onActiveEditorChanged;

  /// A stable layer above both editor pages and below either library drawer.
  final Widget? fixedOverlay;

  static ZephyrDualEditorPagerController? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_DualEditorPagerScope>()
          ?.controller;

  static ZephyrDualEditorPagerController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No ZephyrDualEditorPager ancestor found.');
    return controller!;
  }

  /// Finds the drawer that contains [context], if it is one of this pager's
  /// two book sidebars.
  static ZephyrDualEditorDrawerController? drawerMaybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<_DualDrawerScope>()
      ?.controller;

  @override
  State<ZephyrDualEditorPager> createState() => _ZephyrDualEditorPagerState();
}

class ZephyrDualEditorPagerController extends ChangeNotifier {
  _ZephyrDualEditorPagerState? _state;

  int get activeEditor => _state?._activeEditor ?? 0;

  void openStartDrawer() => _state?._openStartDrawer();
  void openEndDrawer() => _state?._openEndDrawer();
  void closeDrawers() => _state?._closeDrawers();

  void _emit() => notifyListeners();
}

class _DualEditorPagerScope extends InheritedWidget {
  const _DualEditorPagerScope({required this.controller, required super.child});

  final ZephyrDualEditorPagerController controller;

  @override
  bool updateShouldNotify(_DualEditorPagerScope oldWidget) =>
      controller != oldWidget.controller;
}

class ZephyrDualEditorDrawerController {
  const ZephyrDualEditorDrawerController(this.close);

  final VoidCallback close;
}

class _DualDrawerScope extends InheritedWidget {
  const _DualDrawerScope({required this.controller, required super.child});

  final ZephyrDualEditorDrawerController controller;

  @override
  bool updateShouldNotify(_DualDrawerScope oldWidget) =>
      controller != oldWidget.controller;
}

class _ZephyrDualEditorPagerState extends State<ZephyrDualEditorPager>
    with TickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 240);
  static const _minFlingVelocity = 180.0;

  late final AnimationController _page;
  late final AnimationController _startDrawer;
  late final AnimationController _endDrawer;
  late final ZephyrDualEditorPagerController _controller;

  double _dragStartPage = 0;
  double _dragStartStartDrawer = 0;
  double _dragStartEndDrawer = 0;
  double? _dragOriginX;
  bool _dragBlocked = false;
  bool _librarySwipeBlocked = false;
  bool _ignoreDrag = false;
  int _activeEditor = 0;

  bool get _drawerVisible =>
      _startDrawer.value > 0.001 || _endDrawer.value > 0.001;

  @override
  void initState() {
    super.initState();
    _controller = ZephyrDualEditorPagerController().._state = this;
    _page = AnimationController(vsync: this, lowerBound: 0, upperBound: 1)
      ..addListener(_onAnimationTick);
    _startDrawer = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 1,
    )..addListener(_onAnimationTick);
    _endDrawer = AnimationController(vsync: this, lowerBound: 0, upperBound: 1)
      ..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _controller
      .._state = null
      ..dispose();
    _page.dispose();
    _startDrawer.dispose();
    _endDrawer.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    final nextActive = _page.value >= 0.5 ? 1 : 0;
    if (nextActive != _activeEditor) {
      _activeEditor = nextActive;
      widget.onActiveEditorChanged?.call(nextActive);
    }
    _controller._emit();
    setState(() {});
  }

  void _openStartDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    _endDrawer.animateTo(0, duration: _settleDuration);
    _page
        .animateTo(0, duration: _settleDuration, curve: Curves.easeOutCubic)
        .whenComplete(() {
          if (mounted) {
            _startDrawer.animateTo(
              1,
              duration: _settleDuration,
              curve: Curves.easeOutCubic,
            );
          }
        });
  }

  void _openEndDrawer() {
    FocusManager.instance.primaryFocus?.unfocus();
    _startDrawer.animateTo(0, duration: _settleDuration);
    _page
        .animateTo(1, duration: _settleDuration, curve: Curves.easeOutCubic)
        .whenComplete(() {
          if (mounted) {
            _endDrawer.animateTo(
              1,
              duration: _settleDuration,
              curve: Curves.easeOutCubic,
            );
          }
        });
  }

  void _closeDrawers() {
    _startDrawer.animateTo(
      0,
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
    );
    _endDrawer.animateTo(
      0,
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _onDragStart(DragStartDetails details) {
    if (_dragBlocked || _librarySwipeBlocked) {
      _ignoreDrag = true;
      return;
    }
    _ignoreDrag = false;
    _page.stop();
    _startDrawer.stop();
    _endDrawer.stop();
    _dragStartPage = _page.value;
    _dragStartStartDrawer = _startDrawer.value;
    _dragStartEndDrawer = _endDrawer.value;
    _dragOriginX = details.globalPosition.dx;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _onDragUpdate(DragUpdateDetails details, double viewportWidth) {
    if (_ignoreDrag || _dragBlocked || _librarySwipeBlocked) return;
    final origin = _dragOriginX;
    if (origin == null) return;
    final dx = details.globalPosition.dx - origin;
    final drawerWidth = widget.drawerWidth;

    if (_dragStartStartDrawer > 0) {
      _startDrawer.value = (_dragStartStartDrawer + dx / drawerWidth).clamp(
        0.0,
        1.0,
      );
      return;
    }
    if (_dragStartEndDrawer > 0) {
      _endDrawer.value = (_dragStartEndDrawer - dx / drawerWidth).clamp(
        0.0,
        1.0,
      );
      return;
    }

    final page = _dragStartPage - dx / viewportWidth;
    if (page < 0) {
      _page.value = 0;
      _startDrawer.value = (-page * viewportWidth / drawerWidth).clamp(
        0.0,
        1.0,
      );
      return;
    }
    if (page > 1) {
      _page.value = 1;
      _endDrawer.value = ((page - 1) * viewportWidth / drawerWidth).clamp(
        0.0,
        1.0,
      );
      return;
    }
    _page.value = page;
  }

  void _onDragEnd(DragEndDetails details) {
    _dragOriginX = null;
    if (_ignoreDrag || _dragBlocked || _librarySwipeBlocked) {
      _ignoreDrag = false;
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (_startDrawer.value > 0) {
      _settleDrawer(
        _startDrawer,
        open: _shouldKeepDrawerOpen(
          velocity: velocity,
          dragStart: _dragStartStartDrawer,
          value: _startDrawer.value,
          opensWithNegativeVelocity: false,
        ),
      );
      return;
    }
    if (_endDrawer.value > 0) {
      _settleDrawer(
        _endDrawer,
        open: _shouldKeepDrawerOpen(
          velocity: velocity,
          dragStart: _dragStartEndDrawer,
          value: _endDrawer.value,
          opensWithNegativeVelocity: true,
        ),
      );
      return;
    }
    final openCompanion =
        velocity < -_minFlingVelocity ||
        (velocity.abs() < _minFlingVelocity && _page.value >= 0.5);
    _page.animateTo(
      openCompanion ? 1 : 0,
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
    );
  }

  /// Mirrors the compact drawer's low-threshold behavior for both sides.
  bool _shouldKeepDrawerOpen({
    required double velocity,
    required double dragStart,
    required double value,
    required bool opensWithNegativeVelocity,
  }) {
    final openingFling = opensWithNegativeVelocity
        ? velocity < -_minFlingVelocity
        : velocity > _minFlingVelocity;
    final closingFling = opensWithNegativeVelocity
        ? velocity > _minFlingVelocity
        : velocity < -_minFlingVelocity;
    if (openingFling) return true;
    if (closingFling) return false;

    if (dragStart < 0.05 && value > 0.04) return true;
    if (dragStart > 0.95 && value < 0.96) return false;

    return dragStart < 0.5 ? value >= 0.18 : value > 0.82;
  }

  void _settleDrawer(AnimationController drawer, {required bool open}) {
    drawer.animateTo(
      open ? 1 : 0,
      duration: _settleDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final drawerWidth = widget.drawerWidth;
        final startProgress = _startDrawer.value;
        final endProgress = _endDrawer.value;
        final scrimOpacity = (0.45 * (startProgress + endProgress)).clamp(
          0.0,
          0.45,
        );

        return _DualEditorPagerScope(
          controller: _controller,
          child: PopScope(
            canPop: !_drawerVisible,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && _drawerVisible) _closeDrawers();
            },
            child:
                NotificationListener<
                  ZephyrLibrarySidebarSwipeBlockNotification
                >(
                  onNotification: (notification) {
                    _librarySwipeBlocked = notification.blocked;
                    return true;
                  },
                  child:
                      NotificationListener<ZephyrDrawerDragBlockNotification>(
                        onNotification: (notification) {
                          _dragBlocked = notification.blocked;
                          return true;
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragStart: _onDragStart,
                          onHorizontalDragUpdate: (details) =>
                              _onDragUpdate(details, viewportWidth),
                          onHorizontalDragEnd: _onDragEnd,
                          onHorizontalDragCancel: () =>
                              _onDragEnd(DragEndDetails(primaryVelocity: 0)),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                left: -_page.value * viewportWidth,
                                top: 0,
                                bottom: 0,
                                width: viewportWidth * 2,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: viewportWidth,
                                      child: widget.primaryEditor,
                                    ),
                                    SizedBox(
                                      width: viewportWidth,
                                      child: widget.companionEditor,
                                    ),
                                  ],
                                ),
                              ),
                              ...[widget.fixedOverlay].whereType<Widget>(),
                              if (_drawerVisible)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: _closeDrawers,
                                    child: ColoredBox(
                                      color: Colors.black.withValues(
                                        alpha: scrimOpacity,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left:
                                    -drawerWidth + drawerWidth * startProgress,
                                top: 0,
                                bottom: 0,
                                width: drawerWidth,
                                child: Material(
                                  elevation: startProgress > 0 ? 8 : 0,
                                  child: _DualDrawerScope(
                                    controller:
                                        ZephyrDualEditorDrawerController(
                                          _closeDrawers,
                                        ),
                                    child: widget.startDrawer,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -drawerWidth + drawerWidth * endProgress,
                                top: 0,
                                bottom: 0,
                                width: drawerWidth,
                                child: Material(
                                  elevation: endProgress > 0 ? 8 : 0,
                                  child: _DualDrawerScope(
                                    controller:
                                        ZephyrDualEditorDrawerController(
                                          _closeDrawers,
                                        ),
                                    child: widget.endDrawer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
          ),
        );
      },
    );
  }
}
