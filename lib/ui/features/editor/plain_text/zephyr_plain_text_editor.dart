import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plain_text_editor/plain_text_editor.dart';

import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../../domain/use_cases/shortcut_resolver.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../settings/view_models/keyboard_shortcuts_view_model.dart';
import 'zephyr_editor_scrollbar.dart';

/// High-performance plain-text editor backed by per-paragraph [TextPainter]s.
class ZephyrPlainTextEditor extends StatefulWidget {
  const ZephyrPlainTextEditor({
    super.key,
    required this.controller,
    required this.typography,
    required this.onTextChanged,
    required this.onSelectionChanged,
    this.decorations = const [],
    this.scrollController,
    this.focusNode,
    this.readOnly = false,
    required this.cursorColor,
    required this.selectionColor,
    this.header,
    this.scrollbarPadding = EdgeInsets.zero,
    this.bottomObstruction = 0,
    this.typewriterMode = false,
    this.consumeNewline,
    this.shortcuts,
  });

  final PlainTextEditingController controller;
  final EditorTypography typography;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<TextSelection> onSelectionChanged;
  final List<TextSpanDecoration> decorations;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final bool readOnly;
  final Color cursorColor;
  final Color selectionColor;

  /// Scrolls with the document, above the body (e.g. chapter title block).
  final Widget? header;

  /// Outer inset for the editor scrollbar track (e.g. below a floating top bar).
  final EdgeInsets scrollbarPadding;

  /// Extra bottom chrome (quick toolbar + tools drawer) above the soft keyboard
  /// or replacing it. Used for caret visibility.
  final double bottomObstruction;

  /// When true, centers the caret line and dims other paragraphs.
  final bool typewriterMode;

  /// When this returns true, Enter / IME newline is swallowed.
  final bool Function()? consumeNewline;

  /// Customizable shortcuts; null uses platform defaults.
  final KeyboardShortcutsViewModel? shortcuts;

  @override
  State<ZephyrPlainTextEditor> createState() => ZephyrPlainTextEditorState();
}

class ZephyrPlainTextEditorState extends State<ZephyrPlainTextEditor>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PlainTextLayoutEngine _engine;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;
  late final bool _ownsScroll;
  late final bool _ownsFocus;
  PlainTextInputClient? _inputClient;
  late PlainTextGestureHandler _gestures;
  late final AnimationController _caretBlink;
  bool _showCaret = true;
  bool _selecting = false;
  bool _draggingHandle = false;
  /// When true, gaining focus does not open the soft keyboard (e.g. long-press
  /// selection). Cleared when a short tap confirms editing intent.
  bool _suppressImeAttach = false;
  TapDownDetails? _pendingTapDetails;
  final GlobalKey _documentStackKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  double _headerExtent = 0;
  String _lastText = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);
  double _lastKeyboardInset = 0;
  double _lastEffectiveBottomInset = 0;
  /// True while a post-frame IME geometry pump is scheduled (avoid stacking).
  bool _imeGeometryPumpActive = false;

  /// Pointer id for an in-progress drag-select (mouse or long-press).
  int? _selectPointer;
  /// Last global position while drag-selecting (for edge auto-scroll).
  Offset? _selectGlobal;
  bool _selectAutoScrollScheduled = false;
  static const double _selectEdgeZone = 48;
  static const double _selectAutoScrollMaxPerFrame = 28;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = PlainTextLayoutEngine();
    _ownsScroll = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    _ownsFocus = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _caretBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showCaret = false);
          _caretBlink.reverse();
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _showCaret = true);
          _caretBlink.forward();
        }
      });
    _gestures = PlainTextGestureHandler(
      controller: widget.controller,
      engine: _engine,
      onChanged: _onControllerTick,
      documentToGlobal: (o) => o,
    );
    widget.controller.addListener(_onControllerTick);
    widget.controller.firstLineIndent = widget.typography.firstLineIndent;
    _lastText = widget.controller.text;
    _lastSelection = widget.controller.selection;
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_onScroll);
    _inputClient = PlainTextInputClient(
      controller: widget.controller,
      engine: _engine,
      onRemoteEdit: _onControllerTick,
      consumeNewline: _consumeNewline,
    );
    if (_focusNode.hasPrimaryFocus) {
      _attachIme();
    }
  }

  bool _consumeNewline() => widget.consumeNewline?.call() ?? false;

  @override
  void didUpdateWidget(ZephyrPlainTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
      _gestures = PlainTextGestureHandler(
        controller: widget.controller,
        engine: _engine,
        onChanged: _onControllerTick,
        documentToGlobal: (o) => o,
      );
      _inputClient?.detach();
      _inputClient = PlainTextInputClient(
        controller: widget.controller,
        engine: _engine,
        onRemoteEdit: _onControllerTick,
        consumeNewline: _consumeNewline,
      );
      if (_focusNode.hasPrimaryFocus) _attachIme();
    } else {
      _inputClient?.consumeNewline = _consumeNewline;
    }
    widget.controller.firstLineIndent = widget.typography.firstLineIndent;
    if ((oldWidget.bottomObstruction - widget.bottomObstruction).abs() > 0.5) {
      _maybeEnsureCaretForBottomInset();
    }
    if (widget.typewriterMode != oldWidget.typewriterMode &&
        widget.typewriterMode &&
        _focusNode.hasPrimaryFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureCaretVisible();
      });
    }
  }

  @override
  void dispose() {
    _stopSelectionDrag();
    if (_draggingHandle && context.mounted) {
      ZephyrDrawerDragBlockNotification(blocked: false).dispatch(context);
    }
    WidgetsBinding.instance.removeObserver(this);
    _inputClient?.detach();
    widget.controller.removeListener(_onControllerTick);
    _focusNode.removeListener(_onFocusChange);
    _scrollController.removeListener(_onScroll);
    _caretBlink.dispose();
    if (_ownsFocus) _focusNode.dispose();
    if (_ownsScroll) _scrollController.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted) return;
    final keyboard = _keyboardBottomInset(context);
    if ((keyboard - _lastKeyboardInset).abs() < 0.5) return;
    _lastKeyboardInset = keyboard;
    // Rebuild so the end-of-document IME spacer matches the keyboard.
    setState(() {});
    // Only scroll when the *effective* covered bottom changes. Opening the
    // tools panel keeps toolbar+panel constant while the IME animates away.
    _maybeEnsureCaretForBottomInset();
  }

  void _maybeEnsureCaretForBottomInset() {
    if (!_focusNode.hasPrimaryFocus) return;
    final effective = _effectiveBottomInset(context);
    // Ignore sub-pixel / animation jitter from IME + toolbar compensation.
    if ((effective - _lastEffectiveBottomInset).abs() < 2.0) {
      _lastEffectiveBottomInset = effective;
      return;
    }
    _lastEffectiveBottomInset = effective;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.hasPrimaryFocus) {
        _ensureCaretVisible();
      }
    });
  }

  /// Soft-keyboard overlap in logical pixels (scaffold does not resize).
  double _keyboardBottomInset(BuildContext context) {
    // Prefer MediaQuery so this State rebuilds when insets change.
    final media = MediaQuery.viewInsetsOf(context).bottom;
    if (media > 0.5) return media;
    final view = View.maybeOf(context);
    if (view == null) return 0;
    return view.viewInsets.bottom / view.devicePixelRatio;
  }

  /// Keyboard plus overlay chrome that covers the bottom of the viewport.
  double _effectiveBottomInset(BuildContext context) =>
      _keyboardBottomInset(context) + widget.bottomObstruction;

  void hideIme() => _inputClient?.hideIme();

  /// Briefly resist IME selection echoes after a paired-punctuation insert.
  void lockPairCaret({
    required int openIndex,
    required int caret,
    required int highlightEnd,
  }) {
    _inputClient?.lockPairCaret(
      openIndex: openIndex,
      caret: caret,
      highlightEnd: highlightEnd,
    );
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
  }

  void showIme() {
    if (widget.readOnly) return;
    _suppressImeAttach = false;
    if (!_focusNode.hasPrimaryFocus) {
      // requestFocus applies on a microtask; attach once primary focus lands.
      _focusNode.requestFocus();
      _scheduleAttachIme();
      return;
    }
    // Same path as a short tap on the caret: re-show without re-focus churn.
    _attachIme();
  }

  Future<void> paste() => _paste();

  void _onScroll() {
    setState(() {});
    // Scroll moves the document body transform; push IME geometry immediately
    // so Chinese candidate windows track the caret while composing.
    _syncImeGeometryToPlatform();
  }

  /// Report document-body size/transform + caret/composing rects to the IME.
  ///
  /// Must use the body stack (same space as [PlainTextLayoutEngine] caret
  /// rects), not the outer viewport — otherwise the candidate window sits at
  /// the wrong place (ignores header/scroll).
  void _syncImeGeometryToPlatform() {
    final client = _inputClient;
    if (client == null || !client.attached) return;
    final box =
        _documentStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    client.updateSizeAndTransform(box.size, box.getTransformTo(null));
    client.syncImeGeometry();
  }

  void _onFocusChange() {
    // Use primary focus so a sibling field (chapter title) does not keep the
    // body IME/caret alive via ancestor [FocusNode.hasFocus].
    if (_focusNode.hasPrimaryFocus) {
      if (!_suppressImeAttach) {
        _attachIme();
      }
      _caretBlink.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasPrimaryFocus) {
          _ensureCaretVisible();
        }
      });
    } else {
      _suppressImeAttach = false;
      _inputClient?.detach();
      _caretBlink.stop();
      setState(() => _showCaret = false);
    }
    setState(() {});
  }

  void _attachIme() {
    if (widget.readOnly ||
        _suppressImeAttach ||
        !_focusNode.hasPrimaryFocus) {
      return;
    }
    // Windows (and multi-view desktop) reject setClient without viewId.
    final viewId = View.maybeOf(context)?.viewId;
    _inputClient?.attach(viewId: viewId);
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasPrimaryFocus) return;
      _syncImeGeometryToPlatform();
      _ensureCaretVisible();
      // EditableText keeps pushing composing/caret rects every frame while
      // attached — needed so CJK candidate windows stay on the caret.
      _scheduleImeGeometryPump();
    });
  }

  /// While the body IME is attached, refresh geometry each frame (scroll,
  /// keyboard inset, and compose updates all move the candidate anchor).
  void _scheduleImeGeometryPump() {
    if (_imeGeometryPumpActive) return;
    _imeGeometryPumpActive = true;
    void pump(Duration _) {
      if (!mounted ||
          !_focusNode.hasPrimaryFocus ||
          _inputClient?.attached != true) {
        _imeGeometryPumpActive = false;
        return;
      }
      _syncImeGeometryToPlatform();
      WidgetsBinding.instance.addPostFrameCallback(pump);
    }

    WidgetsBinding.instance.addPostFrameCallback(pump);
  }

  /// [FocusNode.requestFocus] only becomes primary on a microtask — schedule
  /// attach so desktop keystrokes are not dropped before TextInput is live.
  void _scheduleAttachIme() {
    if (widget.readOnly || _suppressImeAttach) return;
    final focus = _focusNode;
    void tryAttach() {
      if (!mounted || _suppressImeAttach) return;
      if (!focus.hasPrimaryFocus) return;
      _attachIme();
    }

    Future<void>.microtask(tryAttach);
    WidgetsBinding.instance.addPostFrameCallback((_) => tryAttach());
  }

  /// Confirmed short tap: place caret and open the IME. Scroll drags cancel
  /// [GestureDetector.onTap], so they never reach here.
  void _onBodyTap() {
    final details = _pendingTapDetails;
    if (details == null) return;
    _suppressImeAttach = false;
    _focusNode.requestFocus();
    // Always re-show IME: focus may already be true after the user dismissed
    // the soft keyboard. When focus is still settling, [_scheduleAttachIme]
    // waits for primary focus (critical on Windows desktop).
    _attachIme();
    _scheduleAttachIme();
    _gestures.handleTapDown(details, details.localPosition);
  }

  /// Tap in the trailing blank below the document: caret at end + IME.
  void _onEndPaddingTap() {
    if (widget.readOnly) return;
    _suppressImeAttach = false;
    final end = widget.controller.text.length;
    widget.controller.setSelection(TextSelection.collapsed(offset: end));
    _focusNode.requestFocus();
    _attachIme();
    _scheduleAttachIme();
  }

  void _onControllerTick() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final textChanged = text != _lastText;
    final selectionChanged = selection != _lastSelection;
    if (textChanged) {
      _lastText = text;
      widget.onTextChanged(text);
    }
    if (selectionChanged) {
      _lastSelection = selection;
      widget.onSelectionChanged(selection);
    }
    // Typewriter mode recenters on text layout shifts even when the caret
    // offset is unchanged (e.g. soft wrap from a style change).
    if (_focusNode.hasPrimaryFocus &&
        (selectionChanged || (widget.typewriterMode && textChanged))) {
      _ensureCaretVisible();
    }
    if (_focusNode.hasPrimaryFocus) {
      _inputClient?.markImeDirty();
      _resetCaretBlink();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inputClient?.syncImeIfNeeded();
      });
    }
    setState(() {});
  }

  void _resetCaretBlink() {
    _showCaret = true;
    if (_focusNode.hasPrimaryFocus) {
      _caretBlink
        ..stop()
        ..forward(from: 0);
    }
  }

  void _ensureCaretVisible() {
    // Drag-select owns scrolling via edge auto-scroll; jumping here fights it.
    if (_selecting || _draggingHandle) return;
    if (!_scrollController.hasClients) return;
    final caret = _engine.caretRectForOffset(
      widget.controller.selection.extentOffset,
    );
    if (caret == null) return;
    // Document y is relative to the body stack; scroll offset includes top pad
    // and [header].
    final leading = _typewriterModeLeadingPad;
    final top = caret.top + leading + _headerExtent;
    final bottom = caret.bottom + leading + _headerExtent;
    final viewport = _scrollController.position.viewportDimension;
    final keyboard = _effectiveBottomInset(context);
    final max = _scrollController.position.maxScrollExtent;
    if (widget.typewriterMode) {
      final mid = (top + bottom) / 2;
      final visibleHeight = (viewport - keyboard).clamp(1.0, double.infinity);
      final target = mid - visibleHeight / 2;
      _scrollController.jumpTo(target.clamp(0.0, max));
      return;
    }
    final viewTop = _scrollController.offset;
    final viewBottom = viewTop + viewport - keyboard;
    final line =
        widget.typography.fontSize * widget.typography.lineHeight;
    // Keep the caret about two lines above the keyboard / visible bottom.
    final bottomMargin = line * 2;
    final topMargin = line;
    if (top < viewTop + topMargin) {
      _scrollController.jumpTo((top - topMargin).clamp(0.0, max));
    } else if (bottom > viewBottom - bottomMargin) {
      final target = bottom - (viewport - keyboard) + bottomMargin;
      _scrollController.jumpTo(target.clamp(0.0, max));
    }
  }

  /// Half-viewport pad above content so the first lines can sit at mid-screen.
  double get _typewriterModeLeadingPad {
    if (!widget.typewriterMode) return 0;
    if (!_scrollController.hasClients) return 0;
    return _scrollController.position.viewportDimension * 0.5;
  }

  /// Begin drag-select and route subsequent moves even outside the editor.
  void _beginSelectionDrag(PointerEvent event, {required bool fromMouse}) {
    if (widget.readOnly) return;
    if (fromMouse &&
        (event.kind != PointerDeviceKind.mouse ||
            event.buttons != kPrimaryButton)) {
      return;
    }
    _stopSelectionDrag();
    _selecting = true;
    _selectPointer = event.pointer;
    _selectGlobal = event.position;
    GestureBinding.instance.pointerRouter
        .addRoute(event.pointer, _handleSelectPointerRoute);
    final local = _documentLocalForGlobal(event.position);
    if (local != null) {
      _gestures.handleDragStart(local);
    }
    _scheduleSelectAutoScroll();
  }

  void _handleSelectPointerRoute(PointerEvent event) {
    if (!_selecting || event.pointer != _selectPointer) return;
    if (event is PointerMoveEvent) {
      // Mouse may release without a clean up if the window loses focus.
      if (event.kind == PointerDeviceKind.mouse &&
          event.buttons != kPrimaryButton) {
        _stopSelectionDrag();
        return;
      }
      _selectGlobal = event.position;
      _applySelectionAtGlobal(event.position);
      _scheduleSelectAutoScroll();
      return;
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _stopSelectionDrag();
    }
  }

  void _stopSelectionDrag() {
    final pointer = _selectPointer;
    if (pointer != null) {
      GestureBinding.instance.pointerRouter
          .removeRoute(pointer, _handleSelectPointerRoute);
    }
    _selectPointer = null;
    _selectGlobal = null;
    _selecting = false;
    _selectAutoScrollScheduled = false;
  }

  Offset? _documentLocalForGlobal(Offset global) {
    final box =
        _documentStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  void _applySelectionAtGlobal(Offset global, {bool selecting = true}) {
    final local = _documentLocalForGlobal(global);
    if (local == null) return;
    _gestures.handleDragUpdate(local, selecting: selecting);
  }

  Rect? _scrollViewportGlobalRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  /// Scroll delta for a pointer near/outside the viewport edge (px / frame).
  double _selectAutoScrollDelta(Offset global) {
    final viewport = _scrollViewportGlobalRect();
    if (viewport == null) return 0;
    final keyboard = _effectiveBottomInset(context);
    final top = viewport.top;
    final bottom = viewport.bottom - keyboard;
    if (bottom <= top) return 0;
    if (global.dy < top + _selectEdgeZone) {
      final over = (top + _selectEdgeZone) - global.dy;
      return -_selectAutoScrollSpeed(over);
    }
    if (global.dy > bottom - _selectEdgeZone) {
      final over = global.dy - (bottom - _selectEdgeZone);
      return _selectAutoScrollSpeed(over);
    }
    return 0;
  }

  double _selectAutoScrollSpeed(double overscroll) {
    // Ramp with distance past the edge zone so far drags scroll faster.
    final t = (overscroll / _selectEdgeZone).clamp(0.25, 3.0);
    return (_selectAutoScrollMaxPerFrame * t)
        .clamp(2.0, _selectAutoScrollMaxPerFrame * 3);
  }

  void _scheduleSelectAutoScroll() {
    if (_selectAutoScrollScheduled) return;
    if (!_selecting || _selectGlobal == null) return;
    if (_selectAutoScrollDelta(_selectGlobal!) == 0) return;
    _selectAutoScrollScheduled = true;
    WidgetsBinding.instance.scheduleFrameCallback(_pumpSelectAutoScroll);
    WidgetsBinding.instance.scheduleFrame();
  }

  void _pumpSelectAutoScroll(Duration _) {
    _selectAutoScrollScheduled = false;
    if (!mounted || !_selecting) return;
    final global = _selectGlobal;
    if (global == null || !_scrollController.hasClients) return;
    final delta = _selectAutoScrollDelta(global);
    if (delta == 0) return;
    final position = _scrollController.position;
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((next - position.pixels).abs() > 0.5) {
      _scrollController.jumpTo(next);
      // Document moves under a stationary pointer — re-hit selection.
      _applySelectionAtGlobal(global);
    }
    if (_selecting && _selectAutoScrollDelta(global) != 0) {
      _scheduleSelectAutoScroll();
    }
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      if (_headerExtent != 0 && widget.header == null) {
        setState(() => _headerExtent = 0);
      }
      return;
    }
    final next = box.size.height;
    if ((next - _headerExtent).abs() > 0.5) {
      setState(() => _headerExtent = next);
    }
  }

  ShortcutActionId? _resolveAction(KeyEvent event) {
    final shortcuts = widget.shortcuts;
    if (shortcuts != null) {
      return shortcuts.actionForKeyEvent(event);
    }
    return ShortcutResolver(platform: defaultTargetPlatform)
        .actionForKeyEvent(event);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.readOnly || !_focusNode.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final action = _resolveAction(event);
    if (action == null) return KeyEventResult.ignored;
    if (action == ShortcutActionId.closeSettings) {
      return KeyEventResult.ignored;
    }
    return _dispatchEditorAction(action);
  }

  KeyEventResult _dispatchEditorAction(ShortcutActionId action) {
    final c = widget.controller;
    switch (action) {
      case ShortcutActionId.copy:
        _copy();
        return KeyEventResult.handled;
      case ShortcutActionId.cut:
        _cut();
        return KeyEventResult.handled;
      case ShortcutActionId.paste:
        _paste();
        return KeyEventResult.handled;
      case ShortcutActionId.selectAll:
        c.selectAll();
        return KeyEventResult.handled;
      case ShortcutActionId.undo:
        c.undo();
        return KeyEventResult.handled;
      case ShortcutActionId.redo:
        c.redo();
        return KeyEventResult.handled;
      case ShortcutActionId.deleteBackward:
        c.deleteBackward();
        return KeyEventResult.handled;
      case ShortcutActionId.deleteForward:
        c.deleteForward();
        return KeyEventResult.handled;
      case ShortcutActionId.deleteWordBackward:
        c.deleteWordBackward();
        return KeyEventResult.handled;
      case ShortcutActionId.deleteWordForward:
        c.deleteWordForward();
        return KeyEventResult.handled;
      case ShortcutActionId.indent:
        c.insertTabIndent();
        return KeyEventResult.handled;
      case ShortcutActionId.outdent:
        c.outdentTabIndent();
        return KeyEventResult.handled;
      case ShortcutActionId.newline:
        if (_consumeNewline()) return KeyEventResult.handled;
        c.insertNewlineWithIndent();
        return KeyEventResult.handled;
      case ShortcutActionId.moveLeft:
        _moveByChars(-1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.moveRight:
        _moveByChars(1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.moveUp:
        _moveVertical(-1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.moveDown:
        _moveVertical(1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.moveWordLeft:
        c.moveWordLeft();
        return KeyEventResult.handled;
      case ShortcutActionId.moveWordRight:
        c.moveWordRight();
        return KeyEventResult.handled;
      case ShortcutActionId.moveLineStart:
        c.moveLineStart();
        return KeyEventResult.handled;
      case ShortcutActionId.moveLineEnd:
        c.moveLineEnd();
        return KeyEventResult.handled;
      case ShortcutActionId.movePageUp:
        _movePage(-1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.movePageDown:
        _movePage(1, extend: false);
        return KeyEventResult.handled;
      case ShortcutActionId.moveDocumentStart:
        c.moveDocumentStart();
        return KeyEventResult.handled;
      case ShortcutActionId.moveDocumentEnd:
        c.moveDocumentEnd();
        return KeyEventResult.handled;
      case ShortcutActionId.selectLeft:
        _moveByChars(-1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectRight:
        _moveByChars(1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectUp:
        _moveVertical(-1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectDown:
        _moveVertical(1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectWordLeft:
        c.moveWordLeft(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectWordRight:
        c.moveWordRight(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectLineStart:
        c.moveLineStart(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectLineEnd:
        c.moveLineEnd(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectPageUp:
        _movePage(-1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectPageDown:
        _movePage(1, extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectDocumentStart:
        c.moveDocumentStart(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.selectDocumentEnd:
        c.moveDocumentEnd(extend: true);
        return KeyEventResult.handled;
      case ShortcutActionId.closeSettings:
        return KeyEventResult.ignored;
    }
  }

  void _moveByChars(int delta, {required bool extend}) {
    final extent = widget.controller.selection.extentOffset;
    final next = (extent + delta).clamp(0, widget.controller.text.length);
    widget.controller.moveCaret(next, extend: extend);
  }

  void _moveVertical(int direction, {required bool extend}) {
    final extent = widget.controller.selection.extentOffset;
    widget.controller.moveCaret(
      _verticalMove(extent, direction),
      extend: extend,
    );
  }

  void _movePage(int direction, {required bool extend}) {
    if (!_scrollController.hasClients) {
      _moveVertical(direction, extend: extend);
      return;
    }
    final extent = widget.controller.selection.extentOffset;
    final caret = _engine.caretRectForOffset(extent);
    if (caret == null) return;
    final page = _scrollController.position.viewportDimension *
        0.9 *
        direction;
    final target = Offset(caret.left, caret.center.dy + page);
    widget.controller.moveCaret(
      _engine.offsetForPosition(target),
      extend: extend,
    );
  }

  int _verticalMove(int offset, int direction) {
    final caret = _engine.caretRectForOffset(offset);
    if (caret == null) return offset;
    final target = Offset(
      caret.left,
      caret.center.dy + direction * _engine.typography.fontSize *
          _engine.typography.lineHeight,
    );
    return _engine.offsetForPosition(target);
  }

  Future<void> _copy() async {
    final sel = widget.controller.selection;
    if (sel.isCollapsed) return;
    final text = widget.controller.text.substring(sel.start, sel.end);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _cut() async {
    await _copy();
    if (!widget.controller.selection.isCollapsed) {
      widget.controller.replaceSelection('');
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    widget.controller.replaceSelection(text, coalesce: false);
  }

  @override
  Widget build(BuildContext context) {
    // Keep [header] outside the body [Focus] so title focus is not a
    // descendant of the editor focus node (which made hasFocus stay true and
    // routed Backspace/IME into the body while editing the title).
    return LayoutBuilder(
      builder: (context, constraints) {
        _engine.update(
          document: widget.controller.document,
          typography: widget.typography,
          viewportWidth: constraints.maxWidth,
        );
        final scrollOffset =
            _scrollController.hasClients ? _scrollController.offset : 0.0;
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final typewriterLeading =
            widget.typewriterMode ? viewportHeight * 0.5 : 0.0;
        // Culling is document-local; subtract top pad and scrolled header.
        final documentScrollOffset =
            (scrollOffset - typewriterLeading - _headerExtent)
                .clamp(0.0, double.infinity);
        final bodyFocused = _focusNode.hasPrimaryFocus;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureHeader();
          if (!bodyFocused) return;
          _inputClient?.syncImeIfNeeded();
          _syncImeGeometryToPlatform();
        });

        final selection = widget.controller.selection;
        final showHandles = !widget.readOnly &&
            bodyFocused &&
            !selection.isCollapsed &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS);
        final baseCaret = showHandles
            ? _engine.caretRectForOffset(selection.baseOffset)
            : null;
        final extentCaret = showHandles
            ? _engine.caretRectForOffset(selection.extentOffset)
            : null;
        final viewportH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        // Reserve ~half a viewport below the last line so long chapters can
        // scroll the caret above a typical soft keyboard (viewInsets alone
        // are unreliable while the IME animates).
        final imeReserve = viewportH * 0.45;
        final docHeight = _engine.totalHeight;
        final naturalColumnH = _headerExtent + docHeight;
        // If real text still fits in the band above that reserve, do not
        // attach trailing room — otherwise a short chapter can be scrolled
        // until the text leaves the screen. Typewriter mode always keeps a
        // half-viewport pad so the caret line can sit at mid-screen.
        final fitsAboveImeReserve =
            !widget.typewriterMode &&
            naturalColumnH <= viewportH - imeReserve + 0.5;
        final endScrollRoom = widget.typewriterMode
            ? (viewportH * 0.5 > imeReserve ? viewportH * 0.5 : imeReserve)
            : (fitsAboveImeReserve ? 0.0 : imeReserve);
        // Short chapters: fill the viewport so taps below the last line work.
        // Longer chapters: body is just the document height.
        final minBodyHeight = fitsAboveImeReserve
            ? (viewportH - _headerExtent).clamp(0.0, double.infinity)
            : 0.0;
        final bodyHeight =
            docHeight < minBodyHeight ? minBodyHeight : docHeight;

        final scrollView = ScrollConfiguration(
          // Same Material stretch as the workspace sidebar ListView.
          // Scrollbars are applied outside so mobile can use the circular
          // thumb without stacking a desktop RawScrollbar underneath.
          behavior: const _MaterialStretchScrollBehavior(),
          child: SingleChildScrollView(
            controller: _scrollController,
            // Lock scrolling while a selection handle owns the pointer;
            // otherwise the scroll drag wins the arena and "eats" the handle.
            // Clamping + Material stretch: content stays in-bounds, edge
            // overscroll uses the soft stretch indicator.
            physics: _draggingHandle
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (typewriterLeading > 0) SizedBox(height: typewriterLeading),
                if (widget.header != null)
                  KeyedSubtree(key: _headerKey, child: widget.header!),
                Focus(
                  focusNode: _focusNode,
                  onKeyEvent: _onKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                      maxWidth: constraints.maxWidth,
                      minHeight: minBodyHeight,
                    ),
                    child: Stack(
                      key: _documentStackKey,
                      clipBehavior: Clip.none,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.text,
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            // Moves/ups are routed globally from
                            // [_beginSelectionDrag] so drag-select continues
                            // (and auto-scrolls) outside the editor bounds.
                            onPointerDown: widget.readOnly
                                ? null
                                : (event) {
                                    if (event.kind == PointerDeviceKind.mouse &&
                                        event.buttons == kPrimaryButton) {
                                      _suppressImeAttach = false;
                                      _focusNode.requestFocus();
                                      _attachIme();
                                      _scheduleAttachIme();
                                      _beginSelectionDrag(
                                        event,
                                        fromMouse: true,
                                      );
                                    }
                                  },
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapDown: (details) {
                                // Defer focus/IME to [onTap] so a finger-down
                                // that becomes a scroll does not open the
                                // keyboard.
                                _pendingTapDetails = details;
                              },
                              onTap: _onBodyTap,
                              onLongPressStart: widget.readOnly
                                  ? null
                                  : (details) {
                                      // Selection without popping the IME until
                                      // the press ends (or a short tap follows).
                                      _suppressImeAttach = true;
                                      _focusNode.requestFocus();
                                      _selecting = true;
                                      _selectGlobal = details.globalPosition;
                                      _gestures.handleDragStart(
                                        details.localPosition,
                                      );
                                      _scheduleSelectAutoScroll();
                                    },
                              onLongPressMoveUpdate: widget.readOnly
                                  ? null
                                  : (details) {
                                      if (!_selecting) return;
                                      _selectGlobal = details.globalPosition;
                                      _applySelectionAtGlobal(
                                        details.globalPosition,
                                      );
                                      _scheduleSelectAutoScroll();
                                    },
                              onLongPressEnd: widget.readOnly
                                  ? null
                                  : (_) {
                                      _selectGlobal = null;
                                      _selecting = false;
                                      _selectAutoScrollScheduled = false;
                                      _suppressImeAttach = false;
                                      if (_focusNode.hasPrimaryFocus) {
                                        _attachIme();
                                      }
                                    },
                              child: Semantics(
                                textField: true,
                                multiline: true,
                                readOnly: widget.readOnly,
                                value: widget.controller.text,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: bodyHeight,
                                  child: PlainTextEditorRenderWidget(
                                    controller: widget.controller,
                                    engine: _engine,
                                    typography: widget.typography,
                                    cursorColor: widget.cursorColor,
                                    selectionColor: widget.selectionColor,
                                    showCaret: bodyFocused && _showCaret,
                                    readOnly: widget.readOnly,
                                    typewriterMode: widget.typewriterMode,
                                    decorations: widget.decorations,
                                    viewportHeight: viewportHeight,
                                    scrollOffset: documentScrollOffset,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (baseCaret != null)
                          _SelectionHandle(
                            color: widget.cursorColor,
                            top: baseCaret.bottom,
                            left: baseCaret.left,
                            isBase: true,
                            onDragStart: () => _setDraggingHandle(true),
                            onDragEnd: () => _setDraggingHandle(false),
                            onDragGlobal: (global) =>
                                _moveSelectionHandle(global, isBase: true),
                          ),
                        if (extentCaret != null)
                          _SelectionHandle(
                            color: widget.cursorColor,
                            top: extentCaret.bottom,
                            left: extentCaret.left,
                            isBase: false,
                            onDragStart: () => _setDraggingHandle(true),
                            onDragEnd: () => _setDraggingHandle(false),
                            onDragGlobal: (global) =>
                                _moveSelectionHandle(global, isBase: false),
                          ),
                      ],
                    ),
                  ),
                ),
                  SizedBox(
                    height: endScrollRoom,
                    width: double.infinity,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // onTap (not onTapDown): scroll drags must not open the IME.
                      onTap: widget.readOnly ? null : _onEndPaddingTap,
                    ),
                  ),
                ],
              ),
            ),
          );

        // Circular thumb is mobile-only; desktop keeps the Material scrollbar.
        final useCircularScrollbar =
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
        if (useCircularScrollbar) {
          return ZephyrEditorScrollbar(
            controller: _scrollController,
            padding: widget.scrollbarPadding,
            child: scrollView,
          );
        }
        return Scrollbar(
          controller: _scrollController,
          child: scrollView,
        );
      },
    );
  }

  void _setDraggingHandle(bool dragging) {
    if (_draggingHandle == dragging) return;
    setState(() => _draggingHandle = dragging);
    // Block the compact swipe-drawer open gesture for this pointer. Dispatched
    // on pointer down (before drag slop) so the drawer can ignore the claim.
    ZephyrDrawerDragBlockNotification(blocked: dragging).dispatch(context);
  }

  void _moveSelectionHandle(Offset globalPosition, {required bool isBase}) {
    final box =
        _documentStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(globalPosition);
    final next = _engine.offsetForPosition(local);
    final sel = widget.controller.selection;
    if (isBase) {
      widget.controller.setSelection(
        TextSelection(baseOffset: next, extentOffset: sel.extentOffset),
      );
    } else {
      widget.controller.setSelection(
        TextSelection(baseOffset: sel.baseOffset, extentOffset: next),
      );
    }
  }
}

/// Material Design edge stretch (same indicator the sidebar ListView uses).
class _MaterialStretchScrollBehavior extends ScrollBehavior {
  const _MaterialStretchScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Parent wraps with ZephyrEditorScrollbar (mobile) or Scrollbar (desktop).
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}

/// Mobile selection endpoint. Uses raw [Listener] events so the scroll view
/// cannot steal the pointer via the gesture arena.
class _SelectionHandle extends StatefulWidget {
  const _SelectionHandle({
    required this.color,
    required this.top,
    required this.left,
    required this.isBase,
    required this.onDragStart,
    required this.onDragEnd,
    required this.onDragGlobal,
  });

  final Color color;
  final double top;
  final double left;
  final bool isBase;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final ValueChanged<Offset> onDragGlobal;

  @override
  State<_SelectionHandle> createState() => _SelectionHandleState();
}

class _SelectionHandleState extends State<_SelectionHandle> {
  int? _activePointer;
  static const double _hitSize = 48;
  static const double _visualSize = 22;

  Offset _aimPoint(Offset globalPosition) {
    // Knobs sit under the caret; aim at the text line above the finger.
    return globalPosition.translate(0, -_hitSize * 0.35);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top - 4,
      left: widget.left - _hitSize / 2,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _activePointer = event.pointer;
          widget.onDragStart();
        },
        onPointerMove: (event) {
          if (event.pointer != _activePointer) return;
          widget.onDragGlobal(_aimPoint(event.position));
        },
        onPointerUp: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onDragEnd();
        },
        onPointerCancel: (event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onDragEnd();
        },
        child: SizedBox(
          width: _hitSize,
          height: _hitSize,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: _visualSize,
              height: _visualSize,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

