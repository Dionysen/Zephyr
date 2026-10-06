import 'package:flutter/material.dart';

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

class _DropdownOverlay<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: Offset(0, triggerHeight + ZephyrControls.menuInsets),
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
              width: width,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final selected = item.value == value;
                      return Material(
                        color: selected
                            ? theme.colorScheme.secondaryContainer
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => onSelected(item.value),
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
              ),
            ),
          ),
        ),
      ],
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
