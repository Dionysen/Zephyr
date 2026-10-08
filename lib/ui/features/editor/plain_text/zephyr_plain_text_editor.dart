import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  State<ZephyrPlainTextEditor> createState() => _ZephyrPlainTextEditorState();
}

class _ZephyrPlainTextEditorState extends State<ZephyrPlainTextEditor>
    with SingleTickerProviderStateMixin {
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
  String _lastText = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);

  @override
  void initState() {
    super.initState();
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
    if (_focusNode.hasFocus) {
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
      if (_focusNode.hasFocus) _attachIme();
    }
    widget.controller.firstLineIndent = widget.typography.firstLineIndent;
  }

  @override
  void dispose() {
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

  void _onScroll() {
    setState(() {});
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _attachIme();
      _caretBlink.forward();
    } else {
      _inputClient?.detach();
      _caretBlink.stop();
      setState(() => _showCaret = false);
    }
    setState(() {});
  }

  void _attachIme() {
    if (widget.readOnly) return;
    _inputClient?.attach();
    _inputClient?.markImeDirty();
    _inputClient?.syncImeIfNeeded();
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
      _ensureCaretVisible();
    }
    _inputClient?.markImeDirty();
    _resetCaretBlink();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputClient?.syncImeIfNeeded();
    });
  }

  void _resetCaretBlink() {
    _showCaret = true;
    if (_focusNode.hasFocus) {
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
    final viewTop = _scrollController.offset;
    final viewBottom = viewTop + _scrollController.position.viewportDimension;
    const margin = 48.0;
    if (caret.top < viewTop + margin) {
      _scrollController.jumpTo((caret.top - margin).clamp(0.0, _scrollController.position.maxScrollExtent));
    } else if (caret.bottom > viewBottom - margin) {
      _scrollController.jumpTo(
        (caret.bottom - _scrollController.position.viewportDimension + margin)
            .clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.readOnly) return KeyEventResult.ignored;
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
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
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
              !selection.isCollapsed &&
              (defaultTargetPlatform == TargetPlatform.android ||
                  defaultTargetPlatform == TargetPlatform.iOS);
          final baseCaret = showHandles
              ? _engine.caretRectForOffset(selection.baseOffset)
              : null;
          final extentCaret = showHandles
              ? _engine.caretRectForOffset(selection.extentOffset)
              : null;

          return Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 0,
                ),
                child: Stack(
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
                              _gestures.handleDragStart(event.localPosition);
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
                          final minH = constraints.maxHeight.isFinite
                              ? constraints.maxHeight
                              : 0.0;
                          return doc < minH ? minH : doc;
                        }(),
                        child: PlainTextEditorRenderWidget(
                          controller: widget.controller,
                          engine: _engine,
                          typography: widget.typography,
                          cursorColor: widget.cursorColor,
                          selectionColor: widget.selectionColor,
                          showCaret: _focusNode.hasFocus && _showCaret,
                          readOnly: widget.readOnly,
                          decorations: widget.decorations,
                          viewportHeight: viewportHeight,
                          scrollOffset: scrollOffset,
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
                    onDrag: (delta) {
                      final rect = _engine.caretRectForOffset(
                            selection.baseOffset,
                          ) ??
                          baseCaret;
                      final next = _engine.offsetForPosition(
                        Offset(rect.left + delta.dx, rect.center.dy + delta.dy),
                      );
                      widget.controller.setSelection(
                        TextSelection(
                          baseOffset: next,
                          extentOffset: selection.extentOffset,
                        ),
                      );
                    },
                  ),
                if (extentCaret != null)
                  _SelectionHandle(
                    color: widget.cursorColor,
                    top: extentCaret.bottom,
                    left: extentCaret.left,
                    isBase: false,
                    onDrag: (delta) {
                      final rect = _engine.caretRectForOffset(
                            selection.extentOffset,
                          ) ??
                          extentCaret;
                      final next = _engine.offsetForPosition(
                        Offset(rect.left + delta.dx, rect.center.dy + delta.dy),
                      );
                      widget.controller.setSelection(
                        TextSelection(
                          baseOffset: selection.baseOffset,
                          extentOffset: next,
                        ),
                      );
                    },
                  ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectionHandle extends StatelessWidget {
  const _SelectionHandle({
    required this.color,
    required this.top,
    required this.left,
    required this.isBase,
    required this.onDrag,
  });

  final Color color;
  final double top;
  final double left;
  final bool isBase;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left - 10,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Column(
          children: [
            if (!isBase) const SizedBox(height: 0),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

