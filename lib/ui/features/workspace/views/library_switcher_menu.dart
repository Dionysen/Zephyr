import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../domain/models/workspace_layout.dart';
import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';

/// Dock-width upward library panel. [child] is the dock chrome used as the anchor.
class LibrarySwitcherMenu extends StatefulWidget {
  const LibrarySwitcherMenu({
    super.key,
    required this.model,
    required this.onAddLibrary,
    required this.child,
    this.gapAboveDock = 8,
  });

  final LibraryViewModel model;
  final Future<void> Function() onAddLibrary;

  /// Full dock bar; panel matches this width and sits [gapAboveDock] above it.
  final Widget child;
  final double gapAboveDock;

  @override
  State<LibrarySwitcherMenu> createState() => _LibrarySwitcherMenuState();
}

class _LibrarySwitcherMenuState extends State<LibrarySwitcherMenu> {
  final _dockKey = GlobalKey();
  OverlayEntry? _entry;
  var _open = false;

  bool get isOpen => _open;

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void toggle() {
    if (_open) {
      close();
    } else {
      open();
    }
  }

  void open() {
    if (_open) return;
    final box = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_open) open();
      });
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return;

    final dockSize = box.size;
    final dockTopLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final gap = widget.gapAboveDock;

    _entry = OverlayEntry(
      builder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final maxPanelHeight = math.min(420.0, media.size.height * 0.55);
        final theme = Theme.of(overlayContext);
        final l10n = overlayContext.l10n;
        final radius = overlayContext.zephyrBarBorderRadius;
        final model = widget.model;
        // Panel bottom edge sits [gap] above the dock top.
        final bottom = overlayBox.size.height - dockTopLeft.dy + gap;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: close,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: dockTopLeft.dx,
              width: dockSize.width,
              bottom: bottom,
              child: ZephyrFloatingChrome(
                borderRadius: radius,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxPanelHeight,
                    // Lock width to the measured dock — ignore intrinsic shrink.
                    minWidth: dockSize.width,
                    maxWidth: dockSize.width,
                  ),
                  child: ListenableBuilder(
                    listenable: model,
                    builder: (context, _) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in model.libraries)
                              _LibraryRow(
                                entry: entry,
                                selected: model.activeLibraryId == entry.id,
                                onSelect: () {
                                  close();
                                  unawaited(_switch(model, entry));
                                },
                                onRename: () {
                                  close();
                                  unawaited(_rename(model, entry));
                                },
                                onRemove: () {
                                  close();
                                  unawaited(_remove(model, entry));
                                },
                              ),
                            if (model.libraries.isNotEmpty)
                              Divider(
                                height: 1,
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ListTile(
                              dense: true,
                              leading: const Icon(Icons.add, size: 20),
                              title: Text(l10n.librarySwitcherAdd),
                              onTap: () {
                                close();
                                unawaited(widget.onAddLibrary());
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void close() {
    if (!_open) return;
    _removeEntry();
    if (mounted) setState(() => _open = false);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> _switch(
    LibraryViewModel model,
    LibraryRegistryEntry entry,
  ) async {
    await model.switchLibrary(entry.id);
    if (!mounted) return;
    if (model.error != null) {
      ZephyrSnackBar.show(context, context.l10n.librarySwitcherOpenFailed);
    }
  }

  Future<void> _rename(
    LibraryViewModel model,
    LibraryRegistryEntry entry,
  ) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RenameLibraryDialog(
        initialName: entry.displayName,
        title: l10n.librarySwitcherRenameTitle,
        hint: l10n.librarySwitcherRenameHint,
        cancelLabel: l10n.actionCancel,
        saveLabel: l10n.actionSave,
      ),
    );
    if (next == null || !mounted) return;
    final trimmed = next.trim();
    if (trimmed.isEmpty) {
      ZephyrSnackBar.show(context, l10n.librarySwitcherRenameEmpty);
      return;
    }
    await model.renameLibrary(entry.id, trimmed);
  }

  Future<void> _remove(
    LibraryViewModel model,
    LibraryRegistryEntry entry,
  ) async {
    if (!mounted) return;
    final l10n = context.l10n;
    final host = context;
    final ok = await showDialog<bool>(
      context: host,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.librarySwitcherRemoveTitle),
        content: Text(l10n.librarySwitcherRemoveBody(entry.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.librarySwitcherRemoveAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await model.removeLibrary(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _dockKey,
      child: widget.child,
    );
  }
}

/// Owns its [TextEditingController] so cancel/dismiss cannot dispose it while
/// the route exit animation still holds the field.
class _RenameLibraryDialog extends StatefulWidget {
  const _RenameLibraryDialog({
    required this.initialName,
    required this.title,
    required this.hint,
    required this.cancelLabel,
    required this.saveLabel,
  });

  final String initialName;
  final String title;
  final String hint;
  final String cancelLabel;
  final String saveLabel;

  @override
  State<_RenameLibraryDialog> createState() => _RenameLibraryDialogState();
}

class _RenameLibraryDialogState extends State<_RenameLibraryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.hint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.entry,
    required this.selected,
    required this.onSelect,
    required this.onRename,
    required this.onRemove,
  });

  static const _height = 48.0;

  final LibraryRegistryEntry entry;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onSelect,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Icon(
                        selected ? Icons.check : Icons.folder_outlined,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Width == row height; stretch so ink/hit target fills item height.
          _LibraryRowAction(
            width: _height,
            icon: Icons.drive_file_rename_outline,
            tooltip: l10n.librarySwitcherRename,
            onPressed: onRename,
          ),
          _LibraryRowAction(
            width: _height,
            icon: Icons.link_off_outlined,
            tooltip: l10n.librarySwitcherRemove,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Square control flush to the row edge; height comes from [CrossAxisAlignment.stretch].
class _LibraryRowAction extends StatelessWidget {
  const _LibraryRowAction({
    required this.width,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final double width;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        type: MaterialType.transparency,
        child: Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Book-stack mark for the dock: upright volumes + one leaning.
class _LibraryBuildingIcon extends StatelessWidget {
  const _LibraryBuildingIcon() : size = 24;

  static const _asset = 'branding/library_building.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Library name control inside the dock; toggles [LibrarySwitcherMenu].
class LibrarySwitcherButton extends StatelessWidget {
  const LibrarySwitcherButton({
    super.key,
    required this.model,
    this.padding = const EdgeInsets.fromLTRB(14, 0, 8, 0),
  });

  final LibraryViewModel model;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final menu = context.findAncestorStateOfType<_LibrarySwitcherMenuState>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final open = menu?.isOpen ?? false;
        return InkWell(
          onTap: menu?.toggle,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                const _LibraryBuildingIcon(),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    model.displayLibraryName(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  open ? Icons.expand_more : Icons.expand_less,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
