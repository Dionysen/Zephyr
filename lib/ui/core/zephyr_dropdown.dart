import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'zephyr_controls.dart';

class ZephyrDropdownItem<T> {
  const ZephyrDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// Compact dropdown whose menu matches the closed field's width and row height.
class ZephyrDropdown<T> extends StatefulWidget {
  const ZephyrDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint = 'Select',
  });

  final T? value;
  final List<ZephyrDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String hint;

  @override
  State<ZephyrDropdown<T>> createState() => _ZephyrDropdownState<T>();
}

class _ZephyrDropdownState<T> extends State<ZephyrDropdown<T>> {
  final _link = LayerLink();
  final _triggerKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _isOpen => _entry != null;

  @override
  void didUpdateWidget(covariant ZephyrDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final width = box.size.width;
    final height = box.size.height;
    _entry = OverlayEntry(
      builder: (context) => _DropdownOverlay<T>(
        link: _link,
        width: width,
        triggerHeight: height,
        items: widget.items,
        value: widget.value,
        onSelected: (item) {
          widget.onChanged(item);
          _close();
        },
        onDismiss: _close,
      ),
    );
    Overlay.of(context, debugRequiredFor: widget).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _removeEntry();
    if (mounted) {
      setState(() {});
    }
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;
    return CompositedTransformTarget(
      link: _link,
      child: Material(
        key: _triggerKey,
        color: theme.colorScheme.surfaceContainerHigh,
        shape: ZephyrControls.labeledButtonShape.copyWith(
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: InkWell(
          customBorder: ZephyrControls.labeledButtonShape,
          onTap: _toggle,
          child: SizedBox(
            height: ZephyrControls.fieldHeight,
            child: _DropdownRow(
              leading: Icon(
                _isOpen ? Icons.expand_less : Icons.expand_more,
                size: ZephyrControls.iconSize,
              ),
              label: selected?.label ?? widget.hint,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownOverlay<T> extends StatefulWidget {
  const _DropdownOverlay({
    required this.link,
    required this.width,
    required this.triggerHeight,
    required this.items,
    required this.value,
    required this.onSelected,
    required this.onDismiss,
  });

  final LayerLink link;
  final double width;
  final double triggerHeight;
  final List<ZephyrDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T> onSelected;
  final VoidCallback onDismiss;

  @override
  State<_DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  int? _highlighted;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
    _focus.onKeyEvent = _onKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _query.removeListener(_onQueryChanged);
    _focus.onKeyEvent = null;
    _query.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<ZephyrDropdownItem<T>> get _filtered {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.items;
    }
    return widget.items
        .where((item) => item.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _onQueryChanged() {
    setState(() => _highlighted = null);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_query.value.composing.isValid) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirmHighlight();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveHighlight(int delta) {
    final items = _filtered;
    if (items.isEmpty) {
      return;
    }
    final next = _highlighted == null
        ? (delta > 0 ? 0 : items.length - 1)
        : (_highlighted! + delta).clamp(0, items.length - 1);
    setState(() => _highlighted = next);
    _ensureVisible(next);
  }

  void _confirmHighlight() {
    final items = _filtered;
    if (items.isEmpty) {
      return;
    }
    widget.onSelected(items[_highlighted ?? 0].value);
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      final row = ZephyrControls.fieldHeight;
      final offset = index * row;
      final viewBottom = _scroll.offset + _scroll.position.viewportDimension;
      if (offset < _scroll.offset) {
        _scroll.jumpTo(offset);
      } else if (offset + row > viewBottom) {
        _scroll.jumpTo(offset + row - _scroll.position.viewportDimension);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          offset: Offset(0, widget.triggerHeight + ZephyrControls.menuInsets),
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: .32),
            surfaceTintColor: Colors.transparent,
            shape: ZephyrControls.menuShape.copyWith(
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: widget.width,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DropdownSearchField(
                        controller: _query,
                        focusNode: _focus,
                      ),
                      Divider(height: 1, color: theme.colorScheme.outline),
                      Flexible(
                        child: items.isEmpty
                            ? const SizedBox(
                                height: ZephyrControls.fieldHeight,
                                child: _DropdownRow(
                                  leading: SizedBox(
                                    width: ZephyrControls.iconSize,
                                  ),
                                  label: 'No matches',
                                ),
                              )
                            : ListView.builder(
                                controller: _scroll,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final highlighted = index == _highlighted;
                                  final selected =
                                      item.value == widget.value &&
                                      _highlighted == null;
                                  return Material(
                                    color: highlighted || selected
                                        ? theme.colorScheme.secondaryContainer
                                        : Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          widget.onSelected(item.value),
                                      child: SizedBox(
                                        height: ZephyrControls.fieldHeight,
                                        child: _DropdownRow(
                                          leading: const SizedBox(
                                            width: ZephyrControls.iconSize,
                                          ),
                                          label: item.label,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownSearchField extends StatelessWidget {
  const _DropdownSearchField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: ZephyrControls.fieldHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(Icons.search, size: ZephyrControls.iconSize),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.titleSmall,
                cursorColor: theme.colorScheme.primary,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search',
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    ),
  );
}
