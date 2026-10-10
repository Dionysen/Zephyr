import 'dart:async';

/// Coalesces rapid tools-button taps and serializes IME open/close.
///
/// Taps within [actionDelay] flip a single pending intent (double-tap ≈ no-op).
/// After a commit, further intents queue until [markSettled] or [busyTimeout].
class ToolsPanelToggleGate {
  ToolsPanelToggleGate({
    required this.isDrawerOpen,
    required this.onCommit,
    this.actionDelay = const Duration(milliseconds: 140),
    this.busyTimeout = const Duration(milliseconds: 450),
  });

  /// Splash / ink window before applying panel + IME changes.
  final Duration actionDelay;

  /// Safety unlock if the platform never reports a settled inset.
  final Duration busyTimeout;

  final bool Function() isDrawerOpen;

  /// Applies drawer state; caller should hide/show IME here.
  final void Function(bool openDrawer) onCommit;

  Timer? _debounce;
  Timer? _busyTimer;
  bool? _pendingOpen;
  bool? _queuedOpen;
  var _busy = false;

  bool get isBusy => _busy;

  /// Latest coalesced target, if a tap is still inside [actionDelay].
  bool? get pendingOpen => _pendingOpen;

  void toggle() {
    final baseline = _pendingOpen ?? isDrawerOpen();
    final target = !baseline;
    _pendingOpen = target;
    _debounce?.cancel();
    _debounce = Timer(actionDelay, () {
      _pendingOpen = null;
      _commit(target);
    });
  }

  /// Close without waiting for [actionDelay] (e.g. system / gesture back).
  void close() {
    _debounce?.cancel();
    _pendingOpen = null;
    _commit(false);
  }

  void _commit(bool open) {
    if (_busy) {
      _queuedOpen = open;
      return;
    }
    if (open == isDrawerOpen()) return;
    _busy = true;
    _busyTimer?.cancel();
    _busyTimer = Timer(busyTimeout, markSettled);
    onCommit(open);
  }

  /// Call when the soft keyboard has finished hiding or restoring.
  void markSettled() {
    if (!_busy) return;
    _busyTimer?.cancel();
    _busyTimer = null;
    _busy = false;
    final queued = _queuedOpen;
    _queuedOpen = null;
    if (queued != null && queued != isDrawerOpen()) {
      _commit(queued);
    }
  }

  void dispose() {
    _debounce?.cancel();
    _busyTimer?.cancel();
    _debounce = null;
    _busyTimer = null;
    _pendingOpen = null;
    _queuedOpen = null;
    _busy = false;
  }
}
