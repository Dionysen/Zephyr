import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';

/// Dock-width upward library panel. [child] is the dock chrome used as the anchor.
class LibrarySwitcherMenu extends StatefulWidget {
  const LibrarySwitcherMenu({
    super.key,
    required this.model,
    required this.onChooseDirectory,
    required this.child,
    this.gapAboveDock = 8,
  });

  final LibraryViewModel model;
  final Future<void> Function() onChooseDirectory;

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
                            if (model.activeLibrary case final entry?)
                              ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.folder_outlined,
                                  size: 20,
                                ),
                                title: Text(
                                  entry.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  entry.rootPath,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (model.activeLibrary != null)
                              Divider(
                                height: 1,
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.folder_open_outlined,
                                size: 20,
                              ),
                              title: Text(l10n.librarySwitcherChooseDirectory),
                              onTap: () {
                                close();
                                unawaited(widget.onChooseDirectory());
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

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _dockKey, child: widget.child);
  }
}

/// Book-stack mark for the dock: upright volumes + one leaning.
class _LibraryBuildingIcon extends StatelessWidget {
  const _LibraryBuildingIcon() : size = 24;

  static const _asset = 'branding/library_building.svg';

  final double size;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
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
                Icon(open ? Icons.expand_more : Icons.expand_less, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
