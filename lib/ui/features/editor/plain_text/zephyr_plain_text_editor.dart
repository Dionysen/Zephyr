import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/zephyr_swipe_drawer.dart';
import 'decoration/text_decoration_model.dart';
import 'gestures/plain_text_gesture_handler.dart';
import 'input/plain_text_editing_controller.dart';
import 'input/plain_text_input_client.dart';
import 'layout/editor_typography.dart';
import 'layout/plain_text_layout_engine.dart';
import 'render/plain_text_editor_render_object.dart';

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

  @override
  State<ZephyrPlainTextEditor> createState() => _ZephyrPlainTextEditorState();
}

class _ZephyrPlainTextEditorState extends State<ZephyrPlainTextEditor>
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
  final GlobalKey _documentStackKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();
  double _headerExtent = 0;
  String _lastText = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);
  double _lastKeyboardInset = 0;

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
    );
    if (_focusNode.hasPrimaryFocus) {
      _attachIme();
    }
  }

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
      );
      if (_focusNode.hasPrimaryFocus) _attachIme();
    }
    widget.controller.firstLineIndent = widget.typography.firstLineIndent;
  }

  @override
  void dispose() {
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
    if (!mounted || !_focusNode.hasPrimaryFocus) return;
    final view = View.maybeOf(context);
    if (view == null) return;
    final keyboard = view.viewInsets.bottom / view.devicePixelRatio;
    if ((keyboard - _lastKeyboardInset).abs() < 0.5) return;
    _lastKeyboardInset = keyboard;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.hasPrimaryFocus) {
        _ensureCaretVisible();
      }
    });
  }

  void _onScroll() {
    setState(() {});
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
  }

  void _onFocusChange() {
    // Use primary focus so a sibling field (chapter title) does not keep the
    // body IME/caret alive via ancestor [FocusNode.hasFocus].
    if (_focusNode.hasPrimaryFocus) {
      _attachIme();
      _caretBlink.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasPrimaryFocus) {
          _ensureCaretVisible();
        }
      });
    } else {
      _inputClient?.detach();
      _caretBlink.stop();
      setState(() => _showCaret = false);
    }
    setState(() {});
  }

  void _attachIme() {
    if (widget.readOnly || !_focusNode.hasPrimaryFocus) return;
    _inputClient?.attach();
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.hasPrimaryFocus) {
        _ensureCaretVisible();
      }
    });
  }

  void _onControllerTick() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    if (text != _lastText) {
      _lastText = text;
      widget.onTextChanged(text);
    }
    if (selection != _lastSelection) {
      _lastSelection = selection;
      widget.onSelectionChanged(selection);
      if (_focusNode.hasPrimaryFocus) {
        _ensureCaretVisible();
      }
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
    if (!_scrollController.hasClients) return;
    final caret = _engine.caretRectForOffset(
      widget.controller.selection.extentOffset,
    );
    if (caret == null) return;
    // Document y is relative to the body stack; scroll offset includes [header].
    final top = caret.top + _headerExtent;
    final bottom = caret.bottom + _headerExtent;
    final viewTop = _scrollController.offset;
    final viewport = _scrollController.position.viewportDimension;
    // When the scaffold does not shrink for the IME, viewInsets still covers
    // the caret; when it does resize, insets are usually 0 and viewport is
    // already shorter — subtracting both never double-counts.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final viewBottom = viewTop + viewport - keyboard;
    final line =
        widget.typography.fontSize * widget.typography.lineHeight;
    // Keep the caret about two lines above the keyboard / visible bottom.
    final bottomMargin = line * 2;
    final topMargin = line;
    final max = _scrollController.position.maxScrollExtent;
    if (top < viewTop + topMargin) {
      _scrollController.jumpTo((top - topMargin).clamp(0.0, max));
    } else if (bottom > viewBottom - bottomMargin) {
      final target = bottom - (viewport - keyboard) + bottomMargin;
      _scrollController.jumpTo(target.clamp(0.0, max));
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

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.readOnly || !_focusNode.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final meta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;

    if (key == LogicalKeyboardKey.tab && !shift) {
      widget.controller.insertTabIndent();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      // IME also sends newline; desktop key path inserts here.
      if (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux) {
        widget.controller.insertNewlineWithIndent();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.backspace) {
      widget.controller.deleteBackward();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      widget.controller.deleteForward();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyA) {
      widget.controller.selectAll();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyZ && !shift) {
      widget.controller.undo();
      return KeyEventResult.handled;
    }
    if (meta && (key == LogicalKeyboardKey.keyZ && shift ||
        key == LogicalKeyboardKey.keyY)) {
      widget.controller.redo();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyC) {
      _copy();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyX) {
      _cut();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyV) {
      _paste();
      return KeyEventResult.handled;
    }
    if (_handleArrow(key, shift: shift, meta: meta)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _handleArrow(
    LogicalKeyboardKey key, {
    required bool shift,
    required bool meta,
  }) {
    final sel = widget.controller.selection;
    final text = widget.controller.text;
    var extent = sel.extentOffset;
    if (key == LogicalKeyboardKey.arrowLeft) {
      extent = meta ? _lineStart(extent) : (extent > 0 ? extent - 1 : 0);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      extent = meta ? _lineEnd(extent) : (extent < text.length ? extent + 1 : text.length);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      extent = _verticalMove(extent, -1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      extent = _verticalMove(extent, 1);
    } else {
      return false;
    }
    if (!shift) {
      widget.controller.setSelection(TextSelection.collapsed(offset: extent));
    } else {
      widget.controller.setSelection(
        TextSelection(baseOffset: sel.baseOffset, extentOffset: extent),
      );
    }
    return true;
  }

  int _lineStart(int offset) {
    final i = widget.controller.document.paragraphIndexForOffset(offset);
    return widget.controller.document.paragraphStarts()[i];
  }

  int _lineEnd(int offset) {
    final doc = widget.controller.document;
    final i = doc.paragraphIndexForOffset(offset);
    final start = doc.paragraphStarts()[i];
    return start + doc.paragraphs[i].length;
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
        // Culling is document-local; subtract the scrolled header extent.
        final documentScrollOffset =
            (scrollOffset - _headerExtent).clamp(0.0, double.infinity);
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final bodyFocused = _focusNode.hasPrimaryFocus;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _measureHeader();
          if (!bodyFocused) return;
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            _inputClient?.updateSizeAndTransform(
              box.size,
              box.getTransformTo(null),
            );
            _inputClient?.syncImeIfNeeded();
          }
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
        final minBodyHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - _headerExtent)
                .clamp(0.0, double.infinity)
            : 0.0;

        return Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            // Lock scrolling while a selection handle owns the pointer;
            // otherwise the scroll drag wins the arena and "eats" the handle.
            physics: _draggingHandle
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                            onPointerDown: widget.readOnly
                                ? null
                                : (event) {
                                    if (event.kind == PointerDeviceKind.mouse &&
                                        event.buttons == kPrimaryButton) {
                                      _selecting = true;
                                      _focusNode.requestFocus();
                                      _attachIme();
                                      _gestures.handleDragStart(
                                        event.localPosition,
                                      );
                                    }
                                  },
                            onPointerMove: widget.readOnly
                                ? null
                                : (event) {
                                    if (!_selecting) return;
                                    if (event.kind == PointerDeviceKind.mouse &&
                                        event.buttons == kPrimaryButton) {
                                      _gestures.handleDragUpdate(
                                        event.localPosition,
                                        selecting: true,
                                      );
                                    }
                                  },
                            onPointerUp: (_) => _selecting = false,
                            onPointerCancel: (_) => _selecting = false,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapDown: (details) {
                                _focusNode.requestFocus();
                                // Always re-show IME: focus may already be true
                                // after the user dismissed the soft keyboard.
                                _attachIme();
                                _gestures.handleTapDown(
                                  details,
                                  details.localPosition,
                                );
                              },
                              onLongPressStart: widget.readOnly
                                  ? null
                                  : (details) {
                                      _selecting = true;
                                      _focusNode.requestFocus();
                                      _gestures.handleDragStart(
                                        details.localPosition,
                                      );
                                    },
                              onLongPressMoveUpdate: widget.readOnly
                                  ? null
                                  : (details) {
                                      _gestures.handleDragUpdate(
                                        details.localPosition,
                                        selecting: true,
                                      );
                                    },
                              onLongPressEnd: (_) => _selecting = false,
                              child: Semantics(
                                textField: true,
                                multiline: true,
                                readOnly: widget.readOnly,
                                value: widget.controller.text,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: () {
                                    final doc = _engine.totalHeight;
                                    return doc < minBodyHeight
                                        ? minBodyHeight
                                        : doc;
                                  }(),
                                  child: PlainTextEditorRenderWidget(
                                    controller: widget.controller,
                                    engine: _engine,
                                    typography: widget.typography,
                                    cursorColor: widget.cursorColor,
                                    selectionColor: widget.selectionColor,
                                    showCaret: bodyFocused && _showCaret,
                                    readOnly: widget.readOnly,
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
              ],
            ),
          ),
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

