import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:plain_text_editor/plain_text_editor.dart';

import '../../../../domain/models/chapter_sort_mode.dart';
import '../../../../domain/models/purewriter_models.dart';
import '../../../../domain/use_cases/chapter_sort.dart';
import '../../../core/breakpoints.dart';
import '../../../core/window_chrome.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_controls.dart';
import '../../../core/zephyr_dialog.dart';
import '../../../core/zephyr_dropdown.dart';
import '../../../core/zephyr_floating_chrome.dart';
import '../../../core/zephyr_icon_toolbar.dart';
import '../../../core/zephyr_resize_handle.dart';
import '../../../core/zephyr_snackbar.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../../core/zephyr_dual_editor_pager.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_menu.dart';
import '../../../core/zephyr_theme.dart';
import '../../editor/view_models/library_view_model.dart';
import '../models/workspace_ai_context_selection.dart';
import 'cloud_backup_quick_button.dart';
import 'library_search_sheet.dart';
import 'library_switcher_menu.dart';
import 'workspace_mobile_tools_drawer.dart';
import 'desktop_floating_sidebar_scope.dart';
import 'workspace_sidebar_library_actions.dart';

enum SidebarMode { docked, drawer, floating }

/// Book button clip: left/right ends are arcs of a true circle whose radius is
/// [radiusFactor] × half the button height (default 3×).
class _BookButtonBorder extends ShapeBorder {
  const _BookButtonBorder({this.radiusFactor = 3});

  final double radiusFactor;

  Path _path(Rect rect) {
    final halfH = rect.height / 2;
    if (halfH <= 0 || rect.width <= 0) return Path()..addRect(rect);
    final r = math.max(halfH * radiusFactor, halfH);
    final d = math.sqrt(r * r - halfH * halfH);
    var end = r - d;
    if (end * 2 > rect.width) end = rect.width / 2;
    final alpha = math.asin((halfH / r).clamp(0.0, 1.0));
    final midY = rect.center.dy;
    final leftCenter = Offset(rect.left + r, midY);
    final rightCenter = Offset(rect.right - r, midY);
    return Path()
      ..moveTo(rect.left + end, rect.top)
      ..lineTo(rect.right - end, rect.top)
      ..arcTo(
        Rect.fromCircle(center: rightCenter, radius: r),
        -alpha,
        2 * alpha,
        false,
      )
      ..lineTo(rect.left + end, rect.bottom)
      ..arcTo(
        Rect.fromCircle(center: leftCenter, radius: r),
        math.pi - alpha,
        2 * alpha,
        false,
      )
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => _BookButtonBorder(radiusFactor: radiusFactor);
}

/// Shared shell for the editor top bar and sidebar library dock.
class WorkspaceSidebar extends StatefulWidget {
  const WorkspaceSidebar({
    super.key,
    required this.model,
    required this.mode,
    required this.openLibrary,
    required this.openSettings,
    this.aiContextEnabled = false,
    this.aiContext,
    this.onCollapse,
  });

  final LibraryViewModel model;
  final SidebarMode mode;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;

  /// For [SidebarMode.floating]: closes the overlay instead of toggling docked width.
  final VoidCallback? onCollapse;

  /// When true, chapter rows show a checkbox for [aiContext] selection.
  final bool aiContextEnabled;
  final WorkspaceAiContextSelection? aiContext;

  @override
  State<WorkspaceSidebar> createState() => _WorkspaceSidebarState();
}

class _WorkspaceSidebarState extends State<WorkspaceSidebar> {
  final _chapterTreeKey = GlobalKey<_ChapterTreeState>();

  LibraryViewModel get model => widget.model;
  bool get _canCreateVolume =>
      !model.isReadOnly && model.selectedBook?.isTrash != true;
  bool get _canReorder => _canCreateVolume;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final drawer = widget.mode == SidebarMode.drawer;
    final floating = widget.mode == SidebarMode.floating;
    return DecoratedBox(
      decoration: floating
          ? const BoxDecoration()
          : BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Column(
          children: [
            if (drawer)
              _DrawerSidebarHeader(
                model: model,
                onToggleAllVolumes: model.hasVolumes
                    ? () => _chapterTreeKey.currentState?.toggleAllVolumes()
                    : null,
                onLocateCurrent: model.article == null
                    ? null
                    : () => _chapterTreeKey.currentState
                          ?.scrollToCurrentArticle(),
                canReorder: _canReorder,
              )
            else ...[
              SizedBox(
                height: WorkspaceHeader.height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!floating && WindowChrome.leadingChromeInset > 0)
                      WindowDragArea(
                        child: SizedBox(
                          width: WindowChrome.leadingChromeInset,
                          height: WorkspaceHeader.height,
                        ),
                      ),
                    // Center lone icon buttons so stretch from the title-bar
                    // row does not turn the theme's 28×28 controls into tall
                    // rectangles (the trailing tool cluster already nests in
                    // its own centered Row).
                    WindowNonDragArea(
                      child: Center(
                        child: IconButton(
                          onPressed:
                              floating
                                  ? widget.onCollapse ?? model.collapseSidebar
                                  : model.toggleSidebar,
                          icon: const Icon(Icons.menu_open),
                          tooltip: l10n.tooltipHideSidebar,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: WindowDragArea(child: SizedBox.expand()),
                    ),
                    WindowNonDragArea(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SidebarAddMenuButton(
                            enabled: _canCreateVolume,
                            model: model,
                          ),
                          IconButton(
                            onPressed: () => unawaited(
                              showLibrarySearchSheet(context, model: model),
                            ),
                            icon: const Icon(Icons.search),
                            tooltip: l10n.tooltipSearchChapters,
                          ),
                          IconButton(
                            onPressed: model.hasVolumes
                                ? () => _chapterTreeKey.currentState
                                      ?.toggleAllVolumes()
                                : null,
                            icon: Icon(
                              model.areAllVolumesExpanded
                                  ? Icons.unfold_less
                                  : Icons.unfold_more,
                            ),
                            tooltip: model.areAllVolumesExpanded
                                ? l10n.tooltipCollapseAll
                                : l10n.tooltipExpandAll,
                          ),
                          IconButton(
                            onPressed: model.article == null
                                ? null
                                : () => _chapterTreeKey.currentState
                                      ?.scrollToCurrentArticle(),
                            icon: const Icon(Icons.my_location_outlined),
                            tooltip: l10n.tooltipLocateCurrentChapter,
                          ),
                          _ChapterSortMenuButton(
                            model: model,
                            canAdjustOrder: _canReorder,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              WorkspaceBookPicker(model: model, library: model.library!),
            ],
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _ChapterTree(
                      key: _chapterTreeKey,
                      model: model,
                      library: model.library!,
                      bottomInset: _LibraryDock.overlayExtentFor(context),
                      aiContextEnabled: widget.aiContextEnabled,
                      aiContext: widget.aiContext,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _LibraryDock(
                      model: model,
                      openLibrary: widget.openLibrary,
                      openSettings: widget.openSettings,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile drawer header: book name + chapter count on the left, tools on the right.
/// Sort-mode menu; “adjust order” toggles drag handles in manual mode only.
class _ChapterSortMenuButton extends StatelessWidget {
  const _ChapterSortMenuButton({
    required this.model,
    required this.canAdjustOrder,
    this.style,
  });

  final LibraryViewModel model;
  final bool canAdjustOrder;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final mode = model.chapterSortMode;
    final adjusting = model.isReorderMode;
    final bookOk =
        model.selectedBook != null && model.selectedBook?.isTrash != true;

    Widget modeItem(ChapterSortMode value, String label) {
      return ZephyrMenu.selectableItem(
        context: context,
        label: label,
        selected: mode == value,
        onPressed: !bookOk ? null : () => model.setChapterSortMode(value),
      );
    }

    return MenuAnchor(
      builder: (context, controller, _) {
        syncFloatingSidebarMenu(context, controller);
        return IconButton(
          style: style,
          onPressed: !bookOk
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          isSelected: adjusting,
          icon: Icon(adjusting ? Icons.swap_vert : Icons.sort),
          selectedIcon: Icon(Icons.swap_vert, color: theme.colorScheme.primary),
          tooltip: adjusting ? l10n.tooltipDoneReordering : l10n.tooltipReorder,
        );
      },
      menuChildren: [
        modeItem(ChapterSortMode.manual, l10n.chapterSortManual),
        MenuItemButton(
          leadingIcon: Icon(
            adjusting ? Icons.check : Icons.drag_indicator,
            color: adjusting ? theme.colorScheme.primary : null,
          ),
          onPressed: !bookOk || !canAdjustOrder || !mode.isManual
              ? null
              : model.toggleReorderMode,
          child: Text(l10n.chapterSortAdjustOrder),
        ),
        const Divider(),
        modeItem(ChapterSortMode.createdAsc, l10n.chapterSortCreatedAsc),
        modeItem(ChapterSortMode.createdDesc, l10n.chapterSortCreatedDesc),
        modeItem(ChapterSortMode.updatedAsc, l10n.chapterSortUpdatedAsc),
        modeItem(ChapterSortMode.updatedDesc, l10n.chapterSortUpdatedDesc),
        modeItem(ChapterSortMode.titleAsc, l10n.chapterSortTitleAsc),
        modeItem(ChapterSortMode.titleDesc, l10n.chapterSortTitleDesc),
      ],
    );
  }
}

/// Plus button that opens a menu to create a chapter or volume.
class _SidebarAddMenuButton extends StatelessWidget {
  const _SidebarAddMenuButton({
    required this.enabled,
    required this.model,
    this.style,
  });

  final bool enabled;
  final LibraryViewModel model;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MenuAnchor(
      builder: (context, controller, _) {
        syncFloatingSidebarMenu(context, controller);
        return IconButton(
          style: style,
          onPressed: !enabled
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          icon: const Icon(Icons.add),
          tooltip: l10n.tooltipAdd,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.note_add_outlined),
          onPressed: () => unawaited(model.createArticle()),
          child: Text(l10n.tooltipNewChapter),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.create_new_folder_outlined),
          onPressed: () => unawaited(model.createVolume()),
          child: Text(l10n.tooltipNewVolume),
        ),
      ],
    );
  }
}

class _DrawerSidebarHeader extends StatelessWidget {
  const _DrawerSidebarHeader({
    required this.model,
    required this.onToggleAllVolumes,
    required this.onLocateCurrent,
    required this.canReorder,
  });

  final LibraryViewModel model;
  final VoidCallback? onToggleAllVolumes;
  final VoidCallback? onLocateCurrent;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final book = model.selectedBook;
    final stats = book == null ? null : model.bookStats(book.id);
    final meta = stats == null
        ? null
        : l10n.bookStatsMeta(stats.volumes, stats.chapters);
    final isTrash = book?.isTrash == true;
    final titleColor = isTrash ? theme.colorScheme.error : null;
    final metaColor = isTrash
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    final toolStyle = ZephyrIconToolbar.style(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 12),
      child: Row(
        children: [
          if (isTrash) ...[
            Icon(
              Icons.delete_outline,
              size: ZephyrControls.mobileIconSize,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book?.name ?? l10n.selectBook,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                  ),
                ),
                if (meta != null)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: metaColor,
                    ),
                  ),
              ],
            ),
          ),
          _SidebarAddMenuButton(
            enabled: canReorder,
            model: model,
            style: toolStyle,
          ),
          IconButton(
            style: toolStyle,
            onPressed: () =>
                unawaited(showLibrarySearchSheet(context, model: model)),
            icon: const Icon(Icons.search),
            tooltip: l10n.tooltipSearchChapters,
          ),
          IconButton(
            style: toolStyle,
            onPressed: onToggleAllVolumes,
            icon: Icon(
              model.areAllVolumesExpanded
                  ? Icons.unfold_less
                  : Icons.unfold_more,
            ),
            tooltip: model.areAllVolumesExpanded
                ? l10n.tooltipCollapseAll
                : l10n.tooltipExpandAll,
          ),
          IconButton(
            style: toolStyle,
            onPressed: model.article == null || onLocateCurrent == null
                ? null
                : onLocateCurrent,
            icon: const Icon(Icons.my_location_outlined),
            tooltip: l10n.tooltipLocateCurrentChapter,
          ),
          _ChapterSortMenuButton(
            model: model,
            canAdjustOrder: canReorder,
            style: toolStyle,
          ),
        ],
      ),
    );
  }
}

/// Stable ids for compact editor “more” sheet tools (order is persisted).
abstract final class WorkspaceMobileToolId {
  static const search = 'search';
  static const typewriter = 'typewriter';
  static const themeMode = 'themeMode';
  static const switchTheme = 'switchTheme';
  static const backup = 'backup';
  static const restore = 'restore';
  static const settings = 'settings';
}

/// One choice inside a desktop overflow submenu (radio-style).
class WorkspaceOverflowSubmenuChoice {
  const WorkspaceOverflowSubmenuChoice({
    required this.id,
    required this.label,
    required this.onSelected,
    this.selected = false,
  });

  final String id;
  final String label;
  final VoidCallback onSelected;
  final bool selected;
}

/// One overflow action for the editor “more” menu.
///
/// Pass tools via [WorkspaceMobileBookBar.tools] (or [toolsBuilder]) so future
/// settings/actions can plug in without changing the bar layout. On desktop,
/// a non-empty [submenu] becomes a cascading [SubmenuButton]; mobile keeps
/// using [onTap] (e.g. a picker sheet).
class WorkspaceMobileTool {
  const WorkspaceMobileTool({
    required this.id,
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.submenu,
    this.checked,
  });

  final String id;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;
  final List<WorkspaceOverflowSubmenuChoice>? submenu;

  /// When set, the row is a toggle: desktop shows a check, mobile highlights
  /// the tile.
  final bool? checked;
}

/// Apply a saved id order; unknown ids are dropped, new tools append in
/// registration order.
List<WorkspaceMobileTool> orderWorkspaceMobileTools(
  List<WorkspaceMobileTool> tools,
  List<String> order,
) {
  if (tools.isEmpty || order.isEmpty) return tools;
  final byId = <String, WorkspaceMobileTool>{
    for (final tool in tools) tool.id: tool,
  };
  final ordered = <WorkspaceMobileTool>[];
  for (final id in order) {
    final tool = byId.remove(id);
    if (tool != null) ordered.add(tool);
  }
  ordered.addAll(byId.values);
  return ordered;
}

/// Floating chrome for the compact editor surface.
class WorkspaceMobileBookBar extends StatelessWidget {
  const WorkspaceMobileBookBar({
    super.key,
    required this.model,
    required this.onOpenMenu,
    this.tools = const [],
    this.toolsBuilder,
    this.transparentBackground = false,
    this.reverse = false,
    this.aiActive = false,
    this.onAiPressed,
  });

  /// Compact floating bar; icon buttons sit at 40 inside a 48-tall shell.
  static const height = 48.0;
  static const _iconButtonSize = 40.0;
  static const _iconSize = 22.0;

  final LibraryViewModel model;
  final VoidCallback onOpenMenu;

  /// Static tools shown in the overflow sheet.
  final List<WorkspaceMobileTool> tools;

  /// Optional builder merged after [tools] when the sheet opens.
  final List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder;

  /// When true, the bar fill is clear so the editor background shows through;
  /// the floating shadow is unchanged.
  final bool transparentBackground;

  /// Mirrors the compact chrome for the right-hand editor page.
  final bool reverse;

  /// When true, the editor surface is showing the AI chat demo.
  final bool aiActive;

  /// Toggles AI chat mode; omitted when the control should stay hidden.
  final VoidCallback? onAiPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => _buildBar(context),
    );
  }

  Widget _buildBar(BuildContext context) {
    final theme = Theme.of(context);
    final library = model.library;
    if (library == null) return const SizedBox.shrink();
    final radius = context.zephyrBarBorderRadius;
    final book = model.selectedBook;
    final isTrash = book?.isTrash == true;
    final l10n = context.l10n;
    final bookName = book?.name ?? l10n.selectBook;

    return ZephyrFloatingChrome(
      borderRadius: radius,
      fillColor: transparentBackground ? Colors.transparent : null,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _endpoint(context, l10n, opensLibrary: !reverse),
              _bookButton(context, theme, library, bookName, book?.id, isTrash),
              if (onAiPressed != null) _aiButton(context, theme),
              _backupButton(context),
              _endpoint(context, l10n, opensLibrary: reverse),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _mobileBarIconStyle(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.76),
      iconSize: _iconSize,
      padding: const EdgeInsets.all(9),
      minimumSize: const Size(_iconButtonSize, _iconButtonSize),
      fixedSize: const Size(_iconButtonSize, _iconButtonSize),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: const CircleBorder(),
    );
  }

  Widget _endpoint(
    BuildContext context,
    AppLocalizations l10n, {
    required bool opensLibrary,
  }) => _MobileBookBarEndpoint(
    opensLibrary: opensLibrary,
    onOpenLibrary: onOpenMenu,
    tools: tools,
    toolsBuilder: toolsBuilder,
    style: _mobileBarIconStyle(context),
    iconSize: _iconSize,
    libraryTooltip: l10n.tooltipOpenLibrary,
    moreTooltip: l10n.tooltipMore,
  );

  Widget _aiButton(BuildContext context, ThemeData theme) {
    final fg = aiActive
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.76);
    final style = _mobileBarIconStyle(context)
        .copyWith(foregroundColor: WidgetStatePropertyAll(fg));
    return Center(
      child: IconButton(
        onPressed: onAiPressed,
        style: style,
        tooltip: context.l10n.tooltipAiAssistant,
        icon: Icon(
          aiActive ? Icons.auto_awesome : Icons.auto_awesome_outlined,
          size: _iconSize,
        ),
      ),
    );
  }

  Widget _backupButton(BuildContext context) => Center(
    child: CloudBackupQuickButton(
      iconSize: _iconSize,
      style: _mobileBarIconStyle(context),
    ),
  );

  Widget _bookButton(
    BuildContext context,
    ThemeData theme,
    WritingLibrary library,
    String bookName,
    String? bookId,
    bool isTrash,
  ) => Expanded(
    child: Material(
      type: MaterialType.transparency,
      shape: const _BookButtonBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const _BookButtonBorder(),
        onTap: () => _showBookSheet(context, library: library),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              if (isTrash) ...[
                Icon(
                  Icons.delete_outline,
                  size: _iconSize,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: _AnimatedBookTitle(
                  titleId: bookId ?? bookName,
                  name: bookName,
                  movesDown: reverse,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isTrash
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showBookSheet(
    BuildContext context, {
    required WritingLibrary library,
  }) async {
    await showWorkspaceMobileBookSheet(context, model: model);
  }
}

/// Keeps both endpoint positions stable while their roles exchange.
class _MobileBookBarEndpoint extends StatelessWidget {
  const _MobileBookBarEndpoint({
    required this.opensLibrary,
    required this.onOpenLibrary,
    required this.tools,
    required this.toolsBuilder,
    required this.style,
    required this.iconSize,
    required this.libraryTooltip,
    required this.moreTooltip,
  });

  final bool opensLibrary;
  final VoidCallback onOpenLibrary;
  final List<WorkspaceMobileTool> tools;
  final List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder;
  final ButtonStyle style;
  final double iconSize;
  final String libraryTooltip;
  final String moreTooltip;

  @override
  Widget build(BuildContext context) => Center(
    child: Builder(
      builder: (buttonContext) {
        final items = resolveWorkspaceOverflowTools(
          buttonContext,
          tools: tools,
          toolsBuilder: toolsBuilder,
        );
        return Center(
          child: IconButton(
            style: style,
            onPressed: opensLibrary
                ? onOpenLibrary
                : items.isEmpty
                ? null
                : () => unawaited(
                    WorkspaceOverflowToolsButton.openMobileDrawer(
                      buttonContext,
                      tools: tools,
                      toolsBuilder: toolsBuilder,
                    ),
                  ),
            icon: _MoreMenuMorphIcon(menu: opensLibrary, size: iconSize),
            tooltip: opensLibrary ? libraryTooltip : moreTooltip,
          ),
        );
      },
    ),
  );
}

class _MoreMenuMorphIcon extends StatelessWidget {
  const _MoreMenuMorphIcon({required this.menu, required this.size});

  final bool menu;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: menu ? 1 : 0),
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeInOutCubic,
    builder: (context, progress, _) => CustomPaint(
      size: Size.square(size),
      painter: _MoreMenuMorphPainter(
        progress: progress,
        color: IconTheme.of(context).color ?? Theme.of(context).hintColor,
      ),
    ),
  );
}

class _MoreMenuMorphPainter extends CustomPainter {
  const _MoreMenuMorphPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final centerX = size.width / 2;
    final halfWidth = lerpDouble(size.width * .1, size.width * .42, progress)!;
    final height = lerpDouble(size.width * .2, size.width * .1, progress)!;
    final radius = Radius.circular(height / 2);
    for (final fraction in [.25, .5, .75]) {
      final centerY = size.height * fraction;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: halfWidth * 2,
            height: height,
          ),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MoreMenuMorphPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _AnimatedBookTitle extends StatelessWidget {
  const _AnimatedBookTitle({
    required this.titleId,
    required this.name,
    required this.movesDown,
    required this.style,
  });

  final String titleId;
  final String name;
  final bool movesDown;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final titleKey = ValueKey(titleId);
    final incomingOffset = Offset(0, movesDown ? 1 : -1);
    final outgoingOffset = Offset(0, -incomingOffset.dy);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            ...previousChildren,
            ...[currentChild].whereType<Widget>(),
          ],
        ),
        transitionBuilder: (child, animation) {
          final isIncoming = child.key == titleKey;
          final position = isIncoming
              ? animation.drive(Tween(begin: incomingOffset, end: Offset.zero))
              : ReverseAnimation(animation)
                    .drive(Tween(begin: Offset.zero, end: outgoingOffset));
          return SlideTransition(position: position, child: child);
        },
        child: SizedBox(
          key: titleKey,
          width: double.infinity,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: style,
          ),
        ),
      ),
    );
  }
}

/// Mobile book grid / list picker (toolbar book name or startup pref).
Future<void> showWorkspaceMobileBookSheet(
  BuildContext context, {
  required LibraryViewModel model,
}) async {
  final library = model.library;
  if (library == null) return;
  FocusManager.instance.primaryFocus?.unfocus();
  await showZephyrModalSheet<void>(
    context: context,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) => _MobileBookSheet(
        hostContext: context,
        model: model,
        library: library,
        scrollController: scrollController,
      ),
    ),
  );
}

/// Resolve overflow tools in persisted order.
List<WorkspaceMobileTool> resolveWorkspaceOverflowTools(
  BuildContext context, {
  List<WorkspaceMobileTool> tools = const [],
  List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder,
}) {
  final built = toolsBuilder?.call(context) ?? const <WorkspaceMobileTool>[];
  final theme = ZephyrScope.maybeOf(context)?.theme;
  return orderWorkspaceMobileTools([
    ...tools,
    ...built,
  ], theme?.ui.mobileToolsOrder ?? const []);
}

/// More button that opens overflow tools.
///
/// Desktop uses [MenuAnchor] (cascading submenus, same chrome as chapter
/// sort). Mobile opens a square-button bottom drawer with long-press reorder.
class WorkspaceOverflowToolsButton extends StatelessWidget {
  const WorkspaceOverflowToolsButton({
    super.key,
    this.tools = const [],
    this.toolsBuilder,
    this.style,
    this.iconSize,
  });

  static const _itemStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(
      Size(ZephyrControls.menuMinWidth, ZephyrControls.menuItemHeight),
    ),
  );

  final List<WorkspaceMobileTool> tools;
  final List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder;
  final ButtonStyle? style;
  final double? iconSize;

  static Future<void> openMobileDrawer(
    BuildContext buttonContext, {
    required List<WorkspaceMobileTool> tools,
    required List<WorkspaceMobileTool> Function(BuildContext context)?
    toolsBuilder,
  }) async {
    final items = resolveWorkspaceOverflowTools(
      buttonContext,
      tools: tools,
      toolsBuilder: toolsBuilder,
    );
    if (items.isEmpty || !buttonContext.mounted) return;
    final themeVm = ZephyrScope.maybeOf(buttonContext)?.theme;
    await showWorkspaceMobileToolsDrawer(
      buttonContext,
      title: buttonContext.l10n.tooltipMore,
      order: themeVm?.ui.mobileToolsOrder,
      onReorder: themeVm == null
          ? null
          : (ids) => themeVm.updateMobileToolsOrder(ids),
      actions: [
        for (final tool in items)
          WorkspaceMobileDrawerAction(
            id: tool.id,
            label: tool.label,
            icon: tool.icon,
            enabled: tool.enabled,
            selected: tool.checked ?? false,
            onTap: tool.onTap,
          ),
      ],
    );
  }

  List<Widget> _desktopMenuChildren(
    BuildContext context,
    List<WorkspaceMobileTool> items,
  ) {
    return [
      for (final tool in items)
        if (tool.submenu case final submenu?
            when submenu.isNotEmpty && tool.enabled)
          SubmenuButton(
            style: _itemStyle,
            leadingIcon: Icon(tool.icon ?? Icons.circle_outlined),
            menuChildren: [
              for (final choice in submenu)
                ZephyrMenu.selectableItem(
                  context: context,
                  label: choice.label,
                  selected: choice.selected,
                  onPressed: choice.onSelected,
                ),
            ],
            child: Text(tool.label),
          )
        else if (tool.checked != null)
          ZephyrMenu.selectableItem(
            context: context,
            label: tool.label,
            selected: tool.checked!,
            leadingIcon: Icon(tool.icon ?? Icons.circle_outlined),
            style: _itemStyle,
            onPressed: !tool.enabled ? null : tool.onTap,
          )
        else
          MenuItemButton(
            style: _itemStyle,
            leadingIcon: Icon(tool.icon ?? Icons.circle_outlined),
            onPressed: !tool.enabled ? null : tool.onTap,
            child: Text(tool.label),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!WindowChrome.isDesktop) {
      return Builder(
        builder: (buttonContext) {
          final items = resolveWorkspaceOverflowTools(
            buttonContext,
            tools: tools,
            toolsBuilder: toolsBuilder,
          );
          return IconButton(
            style: style,
            onPressed: items.isEmpty
                ? null
                : () => unawaited(
                    openMobileDrawer(
                      buttonContext,
                      tools: tools,
                      toolsBuilder: toolsBuilder,
                    ),
                  ),
            icon: Icon(Icons.more_vert, size: iconSize),
            tooltip: l10n.tooltipMore,
          );
        },
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge(
        [
          ZephyrScope.maybeOf(context)?.theme,
          ZephyrScope.maybeOf(context)?.backup,
          ZephyrScope.maybeOf(context)?.editorPreferences,
        ].whereType<Listenable>(),
      ),
      builder: (context, _) {
        final items = resolveWorkspaceOverflowTools(
          context,
          tools: tools,
          toolsBuilder: toolsBuilder,
        );
        return MenuAnchor(
          style: const MenuStyle(
            minimumSize: WidgetStatePropertyAll(
              Size(ZephyrControls.menuMinWidth, 0),
            ),
          ),
          builder: (context, controller, _) {
            syncFloatingSidebarMenu(context, controller);
            return IconButton(
              style: style,
              onPressed: items.isEmpty
                  ? null
                  : () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        FocusManager.instance.primaryFocus?.unfocus();
                        final box = context.findRenderObject() as RenderBox?;
                        final size =
                            box?.size ??
                            const Size(
                              ZephyrControls.buttonSize,
                              ZephyrControls.buttonSize,
                            );
                        // Top under the button; right edges aligned when the
                        // panel is at least [menuMinWidth] wide.
                        controller.open(
                          position: Offset(
                            size.width - ZephyrControls.menuMinWidth,
                            size.height,
                          ),
                        );
                      }
                    },
              icon: Icon(Icons.more_vert, size: iconSize),
              tooltip: l10n.tooltipMore,
            );
          },
          menuChildren: _desktopMenuChildren(context, items),
        );
      },
    );
  }
}

class _MobileBookSheet extends StatefulWidget {
  const _MobileBookSheet({
    required this.hostContext,
    required this.model,
    required this.library,
    required this.scrollController,
  });

  final BuildContext hostContext;
  final LibraryViewModel model;
  final WritingLibrary library;
  final ScrollController scrollController;

  @override
  State<_MobileBookSheet> createState() => _MobileBookSheetState();
}

class _MobileBookSheetState extends State<_MobileBookSheet> {
  static final _tagSplit = RegExp(r'[,;，；]');

  var _reorderMode = false;
  String? _armedDeleteBookId;
  final Set<String> _activeTags = {};

  LibraryViewModel get model => widget.model;
  ScrollController get _scrollController => widget.scrollController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final theme = Theme.of(context);
        final l10n = context.l10n;
        final library = model.library ?? widget.library;
        final allBooks = library.folders;
        final filterTags = _collectFilterTags(allBooks);
        final activeTags = _activeTags.intersection(filterTags.toSet());
        final books = _filteredBooks(allBooks, activeTags);
        final toolStyle = ZephyrIconToolbar.style(context);
        final dualColumn = model.booksSheetDualColumn;

        return ZephyrBottomSheet.listTheme(
          context: context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 4, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.booksSheetTitle,
                      style: ZephyrBottomSheet.titleStyle(theme),
                    ),
                    if (filterTags.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _buildTagFilters(context, filterTags)),
                    ] else
                      const Spacer(),
                    IconButton(
                      style: toolStyle,
                      onPressed: model.isReadOnly
                          ? null
                          : () => _onAddBook(context),
                      icon: const Icon(Icons.library_add_outlined),
                      tooltip: l10n.tooltipNewBook,
                    ),
                    IconButton(
                      style: toolStyle,
                      onPressed: () {
                        model.setBooksSheetDualColumn(!dualColumn);
                      },
                      isSelected: dualColumn,
                      icon: Icon(
                        dualColumn
                            ? Icons.view_agenda_outlined
                            : Icons.grid_view_rounded,
                      ),
                      selectedIcon: Icon(
                        Icons.grid_view_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: dualColumn
                          ? l10n.tooltipBookListLayout
                          : l10n.tooltipBookGridLayout,
                    ),
                    IconButton(
                      style: toolStyle,
                      onPressed: model.isReadOnly
                          ? null
                          : () {
                              setState(() {
                                _reorderMode = !_reorderMode;
                                if (_reorderMode) {
                                  _armedDeleteBookId = null;
                                }
                              });
                            },
                      isSelected: _reorderMode,
                      icon: const Icon(Icons.swap_vert),
                      selectedIcon: Icon(
                        Icons.swap_vert,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: _reorderMode
                          ? l10n.tooltipDoneReordering
                          : l10n.tooltipReorder,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: dualColumn
                    ? _buildGrid(context, books)
                    : _buildList(context, books),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagFilters(BuildContext context, List<String> tags) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final shape =
        theme.extension<ZephyrShapeTheme>()?.labeledButtonShape ??
        ZephyrControls.labeledButtonShape;
    final selectedBg = theme.colorScheme.primary.withValues(alpha: 0.18);
    final idleBg = theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final idleFg = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    final allSelected = _activeTags.isEmpty;

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onPressed,
    }) {
      const chipHeight = 28.0;
      return Center(
        child: Material(
          color: selected ? selectedBg : idleBg,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onPressed,
            child: Container(
              height: chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                label,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  height: 1,
                  leadingDistribution: TextLeadingDistribution.even,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : idleFg,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // +1 for the leading "All" chip. Horizontal ListView needs a bounded height.
    return SizedBox(
      height: ZephyrControls.mobileButtonSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          if (index == 0) {
            return chip(
              label: l10n.booksSheetTagAll,
              selected: allSelected,
              onPressed: () {
                setState(() {
                  if (_activeTags.isEmpty) {
                    _activeTags.addAll(tags);
                  } else {
                    _activeTags.clear();
                  }
                });
              },
            );
          }
          final tag = tags[index - 1];
          final selected = _activeTags.contains(tag);
          return chip(
            label: tag,
            selected: selected,
            onPressed: () {
              setState(() {
                if (selected) {
                  _activeTags.remove(tag);
                } else {
                  _activeTags.add(tag);
                }
              });
            },
          );
        },
      ),
    );
  }

  List<String> _collectFilterTags(List<WritingFolder> books) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final book in books) {
      if (book.isTrash) continue;
      for (final tag in _tagsOf(book)) {
        if (seen.add(tag)) ordered.add(tag);
      }
    }
    return ordered;
  }

  List<WritingFolder> _filteredBooks(
    List<WritingFolder> books,
    Set<String> activeTags,
  ) {
    if (activeTags.isEmpty) return books;
    return books
        .where((book) => _tagsOf(book).any(activeTags.contains))
        .toList(growable: false);
  }

  List<String> _tagsOf(WritingFolder book) {
    final raw = book.tags.trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(_tagSplit)
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
  }

  void _persistBookOrder(
    List<WritingFolder> items, {
    required String draggedId,
    required String targetId,
    required bool insertAfter,
  }) {
    final ids = _reorderSiblingIds(
      siblingIds: items.map((b) => b.id).toList(growable: false),
      draggedId: draggedId,
      targetId: targetId,
      insertAfter: insertAfter,
    );
    if (ids == null) return;
    unawaited(model.reorderBooks(ids));
  }

  Widget _buildList(BuildContext context, List<WritingFolder> books) {
    if (_reorderMode) {
      final items = books.where((b) => !b.isTrash).toList();
      return ReorderableListView.builder(
        key: const ValueKey('book-sheet-reorder'),
        scrollController: _scrollController,
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorderItem: (oldIndex, newIndex) {
          final next = List<WritingFolder>.from(items);
          final item = next.removeAt(oldIndex);
          next.insert(newIndex.clamp(0, next.length), item);
          unawaited(model.reorderBooks(next.map((b) => b.id).toList()));
        },
        itemBuilder: (context, index) {
          final book = items[index];
          return KeyedSubtree(
            key: ValueKey(book.id),
            child: _bookTile(
              context,
              book,
              reorderIndex: index,
              showDivider: index < items.length - 1,
            ),
          );
        },
      );
    }
    return ListView.builder(
      key: const ValueKey('book-sheet-list'),
      controller: _scrollController,
      itemCount: books.length,
      itemBuilder: (context, index) => _bookTile(
        context,
        books[index],
        showDivider: index < books.length - 1,
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<WritingFolder> books) {
    final theme = Theme.of(context);
    final line = BorderSide(
      color: theme.dividerColor.withValues(alpha: 0.5),
      width: ZephyrControls.borderWidth,
    );
    final items = _reorderMode
        ? books.where((b) => !b.isTrash).toList(growable: false)
        : books;
    final rowCount = (items.length + 1) ~/ 2;

    Widget cell(Widget child, {required bool right, required bool bottom}) {
      // Paint borders in the foreground so ListTile's Material does not cover
      // the hairlines.
      return Container(
        foregroundDecoration: BoxDecoration(
          border: Border(
            right: right ? line : BorderSide.none,
            bottom: bottom ? line : BorderSide.none,
          ),
        ),
        child: child,
      );
    }

    Widget bookCell(WritingFolder book) {
      final tile = _bookTile(
        context,
        book,
        showDivider: false,
        reorderHandle: _reorderMode
            ? _SidebarDragHandle<_BookDragData>(
                data: _BookDragData(book.id),
                feedbackLabel: book.name,
              )
            : null,
      );
      if (!_reorderMode) return tile;
      return _BookGridReorderTarget(
        bookId: book.id,
        onAcceptBefore: (draggedId) => _persistBookOrder(
          items,
          draggedId: draggedId,
          targetId: book.id,
          insertAfter: false,
        ),
        onAcceptAfter: (draggedId) => _persistBookOrder(
          items,
          draggedId: draggedId,
          targetId: book.id,
          insertAfter: true,
        ),
        child: tile,
      );
    }

    return ListView.builder(
      key: ValueKey(
        _reorderMode ? 'book-sheet-grid-reorder' : 'book-sheet-grid',
      ),
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: rowCount,
      itemBuilder: (context, rowIndex) {
        final leftIndex = rowIndex * 2;
        final rightIndex = leftIndex + 1;
        final bottom = rowIndex < rowCount - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: cell(
                  bookCell(items[leftIndex]),
                  right: true,
                  bottom: bottom,
                ),
              ),
              Expanded(
                child: cell(
                  rightIndex < items.length
                      ? bookCell(items[rightIndex])
                      : const SizedBox.expand(),
                  right: false,
                  bottom: bottom,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bookTile(
    BuildContext context,
    WritingFolder book, {
    int? reorderIndex,
    Widget? reorderHandle,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selected = book.id == model.selectedBook?.id;
    final isTrash = book.isTrash;
    final stats = model.bookStats(book.id);
    final subtitle =
        _mobileBookSubtitle(book) ??
        l10n.bookStatsMeta(stats.volumes, stats.chapters);
    final accent = isTrash ? theme.colorScheme.error : null;
    final showDelete =
        !isTrash &&
        !_reorderMode &&
        _armedDeleteBookId == book.id &&
        !model.isReadOnly;

    final trailing = <Widget>[
      if (showDelete)
        IconButton(
          tooltip: l10n.tooltipDeleteBook,
          onPressed: () => _onDeleteBook(context, book),
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        ),
      if (!isTrash && !_reorderMode)
        IconButton(
          tooltip: l10n.tooltipEditBook,
          onPressed: model.isReadOnly
              ? null
              : () async {
                  Navigator.of(context).pop();
                  if (!widget.hostContext.mounted) return;
                  await _editBook(widget.hostContext, model: model, book: book);
                },
          icon: const Icon(Icons.edit_outlined),
        ),
      if (reorderHandle != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: reorderHandle,
        )
      else if (reorderIndex != null)
        ReorderableDragStartListener(
          index: reorderIndex,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.drag_handle),
          ),
        ),
    ];

    return ZephyrBottomSheet.withRowDivider(
      context: context,
      showDivider: showDivider,
      child: ListTile(
        selected: selected,
        leading: Icon(
          isTrash ? Icons.delete_outline : Icons.book_outlined,
          color: accent,
          size: ZephyrBottomSheet.rowIconSize,
        ),
        title: Text(
          book.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZephyrBottomSheet.rowTitleStyle(theme, color: accent),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZephyrBottomSheet.rowSubtitleStyle(
            theme,
            color: accent?.withValues(alpha: 0.8),
          ),
        ),
        trailing: trailing.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: trailing),
        onLongPress: isTrash || model.isReadOnly || _reorderMode
            ? null
            : () {
                setState(() {
                  _armedDeleteBookId = _armedDeleteBookId == book.id
                      ? null
                      : book.id;
                });
              },
        onTap: () async {
          if (_armedDeleteBookId != null) {
            setState(() => _armedDeleteBookId = null);
            return;
          }
          if (_reorderMode) return;
          Navigator.of(context).pop();
          await model.selectBook(book.id);
        },
      ),
    );
  }

  Future<void> _onAddBook(BuildContext context) async {
    final result = await showDialog<_BookEditResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _EditBookDialog(
        book: const WritingFolder(id: '', name: '', rank: 0),
        dialogTitle: context.l10n.newBookTitle,
      ),
    );
    if (result == null || !mounted) return;
    await model.createBook(
      name: result.name,
      description: result.description,
      tags: result.tags,
    );
  }

  Future<void> _onDeleteBook(BuildContext context, WritingFolder book) async {
    final l10n = context.l10n;
    if (!model.isBookEmpty(book.id)) {
      if (!context.mounted) return;
      ZephyrSnackBar.show(context, l10n.deleteBookNotEmpty);
      return;
    }
    try {
      await model.deleteBook(book.id);
      if (mounted) setState(() => _armedDeleteBookId = null);
    } on FolderNotEmptyException {
      if (!context.mounted) return;
      ZephyrSnackBar.show(context, l10n.deleteBookNotEmpty);
    }
  }

  String? _mobileBookSubtitle(WritingFolder book) {
    final tags = _tagsOf(book);
    if (tags.isNotEmpty) return tags.first;
    final description = book.description.trim();
    if (description.isEmpty) return null;
    return description;
  }
}

class WorkspaceHeader extends StatelessWidget {
  const WorkspaceHeader({
    super.key,
    required this.model,
    this.showMenuButton = false,
    this.showSidebarToggle = false,
    this.onSidebarToggle,
    this.onOpenMenu,
    this.showDocumentTitle = true,
    this.dimDocumentTitle = false,
    this.transparent = false,
    this.tools = const [],
    this.toolsBuilder,
    this.aiActive = false,
    this.onAiPressed,
  });

  static double get height => WindowChrome.titleBarHeight;

  static const titleMotionDuration = Duration(milliseconds: 240);

  final LibraryViewModel model;
  final bool showMenuButton;
  final bool showSidebarToggle;
  final VoidCallback? onSidebarToggle;
  final VoidCallback? onOpenMenu;

  /// When false, the in-editor chapter title is still on screen — hide the
  /// chrome copy. When true, animate it into the title bar.
  final bool showDocumentTitle;

  /// When true (typewriter mode), paint the chrome title at reduced opacity.
  final bool dimDocumentTitle;

  /// When true, let a host-painted editor background show through (desktop
  /// full-bleed under the title bar).
  final bool transparent;

  /// Static tools for the title-bar overflow menu (same panel as mobile more).
  final List<WorkspaceMobileTool> tools;

  /// Optional builder merged after [tools] when the overflow menu opens.
  final List<WorkspaceMobileTool> Function(BuildContext context)? toolsBuilder;

  final bool aiActive;
  final VoidCallback? onAiPressed;

  bool get _hasOverflowTools => tools.isNotEmpty || toolsBuilder != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final title = model.article?.title.trim();
    final label = title?.isNotEmpty == true ? title! : l10n.untitled;
    final leadingInset = showSidebarToggle
        ? WindowChrome.leadingChromeInset
        : 0.0;
    return Material(
      color: transparent ? Colors.transparent : theme.colorScheme.surface,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leadingInset > 0)
                  WindowDragArea(
                    child: SizedBox(width: leadingInset, height: height),
                  ),
                if (showMenuButton || showSidebarToggle)
                  WindowNonDragArea(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showMenuButton)
                          IconButton(
                            onPressed:
                                onOpenMenu ??
                                () => Scaffold.maybeOf(context)?.openDrawer(),
                            icon: const Icon(Icons.menu),
                            tooltip: l10n.tooltipOpenLibrary,
                          ),
                        if (showSidebarToggle)
                          IconButton(
                            onPressed: onSidebarToggle ?? model.toggleSidebar,
                            icon: const Icon(Icons.menu_open),
                            tooltip: l10n.tooltipOpenSidebar,
                          ),
                      ],
                    ),
                  ),
                const Expanded(child: WindowDragArea(child: SizedBox.expand())),
                if (onAiPressed != null)
                  WindowNonDragArea(
                    child: Center(
                      child: IconButton(
                        onPressed: onAiPressed,
                        tooltip: l10n.tooltipAiAssistant,
                        icon: Icon(
                          aiActive
                              ? Icons.auto_awesome
                              : Icons.auto_awesome_outlined,
                        ),
                        color: aiActive ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ),
                if (_hasOverflowTools)
                  WindowNonDragArea(
                    child: Center(
                      child: WorkspaceOverflowToolsButton(
                        tools: tools,
                        toolsBuilder: toolsBuilder,
                      ),
                    ),
                  ),
                const WindowCaptionButtons(),
                if (WindowChrome.trailingChromeInset > 0)
                  WindowDragArea(
                    child: SizedBox(
                      width: WindowChrome.trailingChromeInset,
                      height: height,
                    ),
                  ),
              ],
            ),
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showMenuButton || showSidebarToggle ? 48 : 16,
                  ),
                  // Slides up into the title bar (and back down) within chrome.
                  child: ClipRect(
                    child: AnimatedSlide(
                      duration: titleMotionDuration,
                      curve: Curves.easeOutCubic,
                      offset: showDocumentTitle
                          ? Offset.zero
                          : const Offset(0, 0.65),
                      child: AnimatedOpacity(
                        duration: titleMotionDuration,
                        curve: Curves.easeOutCubic,
                        opacity: showDocumentTitle ? 1 : 0,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: dimDocumentTitle
                                  ? PlainTextEditorRenderObject
                                        .dimmedParagraphOpacity
                                  : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceBookPicker extends StatelessWidget {
  const WorkspaceBookPicker({
    super.key,
    required this.model,
    required this.library,
    this.dense = false,
  });

  /// Vertical space used by the non-dense floating book picker block.
  static const blockHeight =
      8 + ZephyrControls.fieldHeight + 10; // padding + field

  final LibraryViewModel model;
  final WritingLibrary library;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hostContext = context;
    final books = library.folders;
    final bookById = {for (final book in books) book.id: book};
    final barRadius = context.zephyrBarBorderRadius;
    final dropdown = ZephyrDropdown<String>(
      value: model.selectedBook?.id,
      hint: l10n.selectBook,
      // Non-dense: parent [ZephyrFloatingChrome] owns fill / shadow / radius.
      color: dense ? null : Colors.transparent,
      shape: dense ? null : RoundedRectangleBorder(borderRadius: barRadius),
      showOutline: dense,
      floatingMenu: !dense,
      items: [
        for (final book in books)
          ZephyrDropdownItem(
            value: book.id,
            label: book.name,
            subtitle: _bookSubtitle(book),
          ),
      ],
      onChanged: model.selectBook,
      triggerBuilder: (context, {required selected, required isOpen}) {
        final book = selected == null ? null : bookById[selected.value];
        final stats = book == null ? null : model.bookStats(book.id);
        final meta = stats == null
            ? null
            : l10n.bookStatsMeta(stats.volumes, stats.chapters);
        final theme = Theme.of(context);
        final isTrash = book?.isTrash == true;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 10),
          child: Row(
            children: [
              if (isTrash) ...[
                Icon(
                  Icons.delete_outline,
                  size: ZephyrControls.iconSize,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? l10n.selectBook,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isTrash ? theme.colorScheme.error : null,
                  ),
                ),
              ),
              if (meta != null) ...[
                const SizedBox(width: 8),
                // Non-flex trailing: sits flush before the chevron. Cap width
                // so long English meta ellipsizes instead of overflowing.
                // (Flexible + textAlign does not right-align — the Text
                // shrink-wraps and stays at the start of the flex slot.)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isTrash
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                isOpen ? Icons.expand_less : Icons.expand_more,
                size: ZephyrControls.iconSize,
              ),
            ],
          ),
        );
      },
      itemBuilder:
          (
            context, {
            required item,
            required selected,
            required highlighted,
            required onSelect,
            required onDismiss,
          }) {
            final book = bookById[item.value];
            final subtitle = item.subtitle;
            final theme = Theme.of(context);
            final isTrash = book?.isTrash == true;
            final trashColor = theme.colorScheme.error;
            return Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: onSelect,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: ZephyrControls.buttonSize + 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isTrash ? Icons.delete_outline : Icons.book_outlined,
                          size: ZephyrControls.iconSize,
                          color: isTrash ? trashColor : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: isTrash ? trashColor : null,
                            ),
                          ),
                        ),
                        if (subtitle != null && subtitle.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isTrash
                                    ? trashColor
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!isTrash)
                  Positioned(
                    top:
                        (ZephyrControls.fieldHeight -
                            ZephyrControls.buttonSize) /
                        2,
                    right: 4,
                    width: ZephyrControls.buttonSize,
                    height: ZephyrControls.buttonSize,
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        customBorder: hostContext.zephyrShape.iconButtonShape,
                        onTap: model.isReadOnly || book == null
                            ? null
                            : () {
                                final editing = book;
                                onDismiss();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!hostContext.mounted) {
                                    return;
                                  }
                                  unawaited(
                                    _editBook(
                                      hostContext,
                                      model: model,
                                      book: editing,
                                    ),
                                  );
                                });
                              },
                        child: Icon(
                          Icons.edit_outlined,
                          size: ZephyrControls.iconSize,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
    );
    if (dense) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
        child: dropdown,
      );
    }
    // Match the library dock: surface fill, soft shadow, floating-bar radius.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: ZephyrFloatingChrome(borderRadius: barRadius, child: dropdown),
    );
  }

  String? _bookSubtitle(WritingFolder book) {
    final tags = book.tags.trim();
    if (tags.isNotEmpty) {
      return tags.split(RegExp(r'[,;，；]')).first.trim();
    }
    final description = book.description.trim();
    if (description.isEmpty) return null;
    return description;
  }
}

Future<void> _editBook(
  BuildContext context, {
  required LibraryViewModel model,
  required WritingFolder book,
}) async {
  final result = await showDialog<_BookEditResult>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _EditBookDialog(book: book),
  );
  if (result == null) return;
  await model.updateBook(
    folderId: book.id,
    name: result.name,
    description: result.description,
    tags: result.tags,
  );
}

class _BookEditResult {
  const _BookEditResult({
    required this.name,
    required this.description,
    required this.tags,
  });
  final String name;
  final String description;
  final String tags;
}

class _EditBookDialog extends StatefulWidget {
  const _EditBookDialog({required this.book, this.dialogTitle});

  final WritingFolder book;
  final String? dialogTitle;

  @override
  State<_EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<_EditBookDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.book.name);
    _description = TextEditingController(text: widget.book.description);
    _tags = TextEditingController(text: widget.book.tags);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _BookEditResult(
        name: _name.text.trim(),
        description: _description.text.trim(),
        tags: _tags.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.dialogTitle ?? l10n.editBookTitle,
        style: theme.textTheme.titleLarge,
      ),
      content: zephyrDialogScrollableContent(
        context: context,
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.bookNameLabel,
                  hintText: l10n.bookNameHint,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.bookNameRequired;
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tags,
                decoration: InputDecoration(
                  labelText: l10n.bookTagsLabel,
                  hintText: l10n.bookTagsHint,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                decoration: InputDecoration(
                  labelText: l10n.bookDescriptionLabel,
                  hintText: l10n.bookDescriptionHint,
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionSave)),
      ],
    );
  }
}

class _ChapterTree extends StatefulWidget {
  const _ChapterTree({
    super.key,
    required this.model,
    required this.library,
    this.bottomInset = 0,
    this.aiContextEnabled = false,
    this.aiContext,
  });

  final LibraryViewModel model;
  final WritingLibrary library;
  final double bottomInset;
  final bool aiContextEnabled;
  final WorkspaceAiContextSelection? aiContext;

  @override
  State<_ChapterTree> createState() => _ChapterTreeState();
}

class _ChapterTreeState extends State<_ChapterTree> {
  final _scrollController = ScrollController();
  final _volumeKeys = <String, GlobalKey>{};
  final _chapterKeys = <String, GlobalKey>{};
  String? _restoredBookId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant _ChapterTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.library, oldWidget.library)) {
      _restoredBookId = null;
    }
    final bookId = widget.model.selectedBook?.id;
    if (bookId != _restoredBookId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollIfNeeded();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    widget.model.updateSidebarScrollOffset(_scrollController.offset);
  }

  void _restoreScrollIfNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    final bookId = widget.model.selectedBook?.id;
    if (bookId == null || _restoredBookId == bookId) return;
    final offset = widget.model.sidebarScrollOffset;
    final max = _scrollController.position.maxScrollExtent;
    if (offset > 0 && max == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final bookStill = widget.model.selectedBook?.id;
        if (bookStill != bookId) return;
        final max2 = _scrollController.position.maxScrollExtent;
        _scrollController.jumpTo(offset.clamp(0.0, max2));
        _restoredBookId = bookId;
      });
      return;
    }
    _scrollController.jumpTo(offset.clamp(0.0, max));
    _restoredBookId = bookId;
  }

  GlobalKey _volumeKeyFor(String volumeId) =>
      _volumeKeys.putIfAbsent(volumeId, GlobalKey.new);

  GlobalKey _chapterKeyFor(String chapterId) =>
      _chapterKeys.putIfAbsent(chapterId, GlobalKey.new);

  static const _locateAlignment = 0.25;
  static const _locateCurve = Curves.easeInOutCubic;

  /// Expands the current chapter's volume if needed, then scrolls it into view.
  Future<void> scrollToCurrentArticle() async {
    final articleId = widget.model.article?.id;
    if (articleId == null) return;
    final chapter = widget.library.articles
        .where((item) => item.id == articleId)
        .firstOrNull;
    if (chapter == null) return;

    final volumeId = chapter.categoryId;
    if (volumeId != null && !widget.model.isVolumeExpanded(volumeId)) {
      widget.model.ensureVolumeExpanded(volumeId);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    if (!_scrollController.hasClients) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;
    }

    // Still in the lazy window: [ensureVisible] can animate the full trip.
    final built = _chapterKeyFor(articleId).currentContext;
    if (built != null && built.mounted) {
      await Scrollable.ensureVisible(
        built,
        alignment: _locateAlignment,
        duration: _locateScrollDuration(240),
        curve: _locateCurve,
      );
      return;
    }

    // Far off-screen rows are disposed. Animate to an estimated offset so the
    // list builds along the way — never jumpTo, or the motion disappears.
    final estimated = _estimateChapterScrollOffset(chapter);
    if (estimated == null) return;
    final position = _scrollController.position;
    final destination =
        (estimated - position.viewportDimension * _locateAlignment).clamp(
          0.0,
          position.maxScrollExtent,
        );
    final distance = (destination - position.pixels).abs();
    if (distance >= 1) {
      await _scrollController.animateTo(
        destination,
        duration: _locateScrollDuration(distance),
        curve: _locateCurve,
      );
      if (!mounted) return;
    }
    await _fineTuneChapterVisibility(articleId, chapter);
  }

  Duration _locateScrollDuration(double distance) {
    final ms = (240 + distance * 0.32).round().clamp(280, 720);
    return Duration(milliseconds: ms);
  }

  /// Corrects residual error after an estimated [animateTo] (no animation).
  Future<void> _fineTuneChapterVisibility(
    String articleId,
    ArticleSummary chapter,
  ) async {
    var target = _chapterKeyFor(articleId).currentContext;
    if (target == null) {
      await _scrollTowardChapter(chapter);
      if (!mounted) return;
      target = _chapterKeyFor(articleId).currentContext;
    }
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      alignment: _locateAlignment,
      duration: Duration.zero,
    );
  }

  /// Nudges the sidebar so [chapter] enters the lazy-build window.
  Future<void> _scrollTowardChapter(ArticleSummary chapter) async {
    if (!_scrollController.hasClients) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;
    }
    final estimated = _estimateChapterScrollOffset(chapter);
    if (estimated == null) {
      await WidgetsBinding.instance.endOfFrame;
      return;
    }
    // Prefer putting the estimate near the upper quarter; nudge by ~1 viewport
    // if row-height variance still leaves the row unbuilt.
    for (final alignment in const [0.25, -0.65, 1.15]) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final offset = (estimated - position.viewportDimension * alignment).clamp(
        0.0,
        position.maxScrollExtent,
      );
      _scrollController.jumpTo(offset);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (_chapterKeyFor(chapter.id).currentContext != null) return;
    }
  }

  /// Approximate scroll offset of [chapter] within the sidebar [CustomScrollView].
  double? _estimateChapterScrollOffset(ArticleSummary chapter) {
    final bookId = widget.model.selectedBook?.id;
    if (bookId == null) return null;
    final isTrash = bookId == WritingFolder.trashId;
    final rowHeight = _sampleChapterRowHeight() ?? 88.0;
    final sortMode = widget.model.chapterSortMode;

    final volumeId = chapter.categoryId;
    if (volumeId != null && !isTrash) {
      final volumeSliver = _volumeSliver(volumeId);
      if (volumeSliver == null) return null;
      final chapters = sortArticleSummaries(
        widget.library.articles
            .where(
              (item) => item.folderId == bookId && item.categoryId == volumeId,
            )
            .toList(growable: false),
        sortMode,
      );
      final index = chapters.indexWhere((item) => item.id == chapter.id);
      if (index < 0) return null;
      final header = _headerExtentOf(volumeSliver);
      final total = volumeSliver.geometry?.scrollExtent ?? 0;
      final bodyExtent = (total - header).clamp(0.0, double.infinity);
      final within = _estimateOffsetWithinChapterList(
        chapters,
        index,
        rowHeight,
        listExtent: bodyExtent,
      );
      return volumeSliver.constraints.precedingScrollExtent + header + within;
    }

    // Unfiled chapters are the first sliver in the book list.
    final loose = sortArticleSummaries(
      widget.library.articles
          .where(
            (item) =>
                item.folderId == bookId && (isTrash || item.categoryId == null),
          )
          .toList(growable: false),
      sortMode,
    );
    final index = loose.indexWhere((item) => item.id == chapter.id);
    if (index < 0) return null;
    return _estimateOffsetWithinChapterList(loose, index, rowHeight);
  }

  /// Offset of [index] inside a chapter sliver list, preferring a built sibling.
  double _estimateOffsetWithinChapterList(
    List<ArticleSummary> chapters,
    int index,
    double rowHeight, {
    double listExtent = 0,
  }) {
    for (var i = 0; i < chapters.length; i++) {
      final ctx = _chapterKeys[chapters[i].id]?.currentContext;
      final box = ctx?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final siblingOffset = _sliverChildScrollOffset(box);
      if (siblingOffset == null) continue;
      return siblingOffset + (index - i) * rowHeight;
    }
    if (listExtent > 0 && chapters.isNotEmpty) {
      return listExtent * (index / chapters.length);
    }
    return index * rowHeight;
  }

  double? _sampleChapterRowHeight() {
    for (final key in _chapterKeys.values) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize && box.size.height > 0) {
        return box.size.height;
      }
    }
    return null;
  }

  /// Scroll offset of [object] inside its parent [RenderSliverMultiBoxAdaptor].
  double? _sliverChildScrollOffset(RenderObject object) {
    var current = object;
    for (var parent = current.parent; parent != null; parent = current.parent) {
      if (parent is RenderSliverMultiBoxAdaptor) {
        return parent.childScrollOffset(current);
      }
      current = parent;
    }
    return null;
  }

  RenderSliver? _volumeSliver(String volumeId) {
    final renderObject = _volumeKeyFor(volumeId).currentContext
        ?.findRenderObject();
    return renderObject is RenderSliver ? renderObject : null;
  }

  /// Offset that puts the collapsing volume at the viewport top.
  ///
  /// Single-volume: [SliverConstraints.precedingScrollExtent].
  /// Collapse-all: also subtract chapter bodies of fully scrolled-past volumes
  /// above the active one (they shrink to headers).
  double? _collapseTargetOffset({String? volumeId}) {
    final ids = _volumeKeys.keys.toList(growable: false);
    final String? activeId;
    if (volumeId != null) {
      activeId = volumeId;
    } else {
      String? found;
      for (final id in ids) {
        final sliver = _volumeSliver(id);
        if (sliver == null) continue;
        final painted = sliver.geometry?.paintExtent ?? 0;
        if (sliver.constraints.scrollOffset > 0 && painted > 0) {
          found = id;
          break;
        }
      }
      activeId = found;
    }
    if (activeId == null) return null;

    final active = _volumeSliver(activeId);
    if (active == null || active.constraints.scrollOffset <= 0) return null;

    var target = active.constraints.precedingScrollExtent;
    if (volumeId != null) return target;

    for (final id in ids) {
      if (id == activeId) break;
      final sliver = _volumeSliver(id);
      if (sliver == null) continue;
      final painted = sliver.geometry?.paintExtent ?? 0;
      if (painted > 0) continue;
      final extent = sliver.geometry?.scrollExtent ?? 0;
      final headerExtent = _headerExtentOf(sliver);
      final body = (extent - headerExtent).clamp(0.0, extent);
      target -= body;
    }
    return target;
  }

  double _headerExtentOf(RenderSliver group) {
    if (group is! RenderSliverMainAxisGroup) return 0;
    return group.firstChild?.geometry?.scrollExtent ?? 0;
  }

  void _jumpToAfterLayout(double target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(target.clamp(0.0, max));
    });
  }

  void _toggleVolume(String volumeId) {
    final collapsing = widget.model.isVolumeExpanded(volumeId);
    final target = collapsing
        ? _collapseTargetOffset(volumeId: volumeId)
        : null;
    widget.model.toggleVolume(volumeId);
    if (target != null) _jumpToAfterLayout(target);
  }

  void toggleAllVolumes() {
    final collapsing = widget.model.areAllVolumesExpanded;
    final target = collapsing ? _collapseTargetOffset() : null;
    widget.model.toggleAllVolumes();
    if (target != null) _jumpToAfterLayout(target);
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final library = widget.library;
    final bookId = model.selectedBook?.id;
    if (bookId == null) return const SizedBox();
    final chapters = library.articles
        .where((item) => item.folderId == bookId)
        .toList(growable: false);
    final isTrash = bookId == WritingFolder.trashId;
    final canManage = !model.isReadOnly && !isTrash;
    final sortMode = model.chapterSortMode;
    final showDragHandles =
        canManage && model.isReorderMode && sortMode.isManual;
    final pinnedBackground = Theme.of(context)
        .colorScheme
        .surfaceContainerLowest;
    final volumes = library.categories
        .where((item) => !isTrash && item.folderId == bookId)
        .toList(growable: false);
    final volumeIds = volumes.map((item) => item.id).toList(growable: false);
    final slivers = <Widget>[];
    // Unfiled chapters sit at the top of the book list (not under a header).
    final loose = sortArticleSummaries(
      chapters
          .where((item) => isTrash || item.categoryId == null)
          .toList(growable: false),
      sortMode,
    );
    if (loose.isNotEmpty) {
      final looseIds = loose.map((item) => item.id).toList(growable: false);
      slivers.add(
        SliverList.builder(
          itemCount: loose.length,
          itemBuilder: (context, index) {
            final chapter = loose[index];
            return KeyedSubtree(
              key: _chapterKeyFor(chapter.id),
              child: _ChapterRow(
                chapter: chapter,
                model: model,
                siblingIds: looseIds,
                canManage: canManage,
                showDragHandle: showDragHandles,
                isFirst: index == 0,
                aiContextEnabled: widget.aiContextEnabled,
                aiContext: widget.aiContext,
              ),
            );
          },
        ),
      );
    }
    for (var volumeIndex = 0; volumeIndex < volumes.length; volumeIndex++) {
      final volume = volumes[volumeIndex];
      final volumeChapters = sortArticleSummaries(
        chapters
            .where((item) => item.categoryId == volume.id)
            .toList(growable: false),
        sortMode,
      );
      final chapterIds = volumeChapters
          .map((item) => item.id)
          .toList(growable: false);
      final header = _VolumeRow(
        volume: volume,
        model: model,
        chapterCount: volumeChapters.length,
        siblingIds: volumeIds,
        canManage: canManage,
        showDragHandle: showDragHandles,
        isFirst: volumeIndex == 0,
        onToggle: () => _toggleVolume(volume.id),
        onChapterAppended: () async {
          await WidgetsBinding.instance.endOfFrame;
          if (mounted) await scrollToCurrentArticle();
        },
      );
      // Keep a stable SliverMainAxisGroup so collapsing during a volume drag
      // does not dispose the active Draggable.
      slivers.add(
        SliverMainAxisGroup(
          key: _volumeKeyFor(volume.id),
          slivers: [
            PinnedHeaderSliver(
              child: ColoredBox(color: pinnedBackground, child: header),
            ),
            if (model.isVolumeExpanded(volume.id) && volumeChapters.isNotEmpty)
              SliverList.builder(
                itemCount: volumeChapters.length,
                itemBuilder: (context, index) {
                  final chapter = volumeChapters[index];
                  return KeyedSubtree(
                    key: _chapterKeyFor(chapter.id),
                    child: _ChapterRow(
                      chapter: chapter,
                      model: model,
                      siblingIds: chapterIds,
                      canManage: canManage,
                      showDragHandle: showDragHandles,
                      isFirst: index == 0,
                      aiContextEnabled: widget.aiContextEnabled,
                      aiContext: widget.aiContext,
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }
    slivers.add(
      SliverToBoxAdapter(child: SizedBox(height: 12 + widget.bottomInset)),
    );
    return CustomScrollView(controller: _scrollController, slivers: slivers);
  }
}

class _VolumeDragData {
  const _VolumeDragData(this.volumeId);
  final String volumeId;
}

class _ChapterDragData {
  const _ChapterDragData({required this.articleId, required this.categoryId});
  final String articleId;
  final String? categoryId;
}

class _BookDragData {
  const _BookDragData(this.bookId);
  final String bookId;
}

/// Drop overlay for the books sheet grid; insert before/after from pointer X.
class _BookGridReorderTarget extends StatefulWidget {
  const _BookGridReorderTarget({
    required this.bookId,
    required this.onAcceptBefore,
    required this.onAcceptAfter,
    required this.child,
  });

  final String bookId;
  final void Function(String draggedId) onAcceptBefore;
  final void Function(String draggedId) onAcceptAfter;
  final Widget child;

  @override
  State<_BookGridReorderTarget> createState() => _BookGridReorderTargetState();
}

class _BookGridReorderTargetState extends State<_BookGridReorderTarget> {
  bool _insertAfter = false;

  bool _isAfter(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return _insertAfter;
    return box.globalToLocal(global).dx > box.size.width / 2;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<_BookDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.bookId != widget.bookId,
      onMove: (details) {
        final after = _isAfter(details.offset);
        if (after != _insertAfter) setState(() => _insertAfter = after);
      },
      onLeave: (_) {
        if (_insertAfter) setState(() => _insertAfter = false);
      },
      onAcceptWithDetails: (details) {
        final after = _isAfter(details.offset);
        setState(() => _insertAfter = false);
        if (after) {
          widget.onAcceptAfter(details.data.bookId);
        } else {
          widget.onAcceptBefore(details.data.bookId);
        }
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return Stack(
          children: [
            widget.child,
            if (highlight)
              Positioned(
                left: _insertAfter ? null : 0,
                right: _insertAfter ? 0 : null,
                top: 0,
                bottom: 0,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.primary,
                  child: const SizedBox(width: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Moves [draggedId] before/after [targetId] within a sibling id list.
List<String>? _reorderSiblingIds({
  required List<String> siblingIds,
  required String draggedId,
  required String targetId,
  required bool insertAfter,
}) {
  if (draggedId == targetId) return null;
  final ids = List<String>.from(siblingIds);
  final from = ids.indexOf(draggedId);
  var to = ids.indexOf(targetId);
  if (from < 0 || to < 0) return null;
  final item = ids.removeAt(from);
  if (from < to) to -= 1;
  if (insertAfter) to += 1;
  ids.insert(to.clamp(0, ids.length), item);
  return ids;
}

/// Drop overlay that keeps idle spacing; insert before/after from pointer Y.
class _ReorderTarget<T extends Object> extends StatefulWidget {
  const _ReorderTarget({
    required this.enabled,
    required this.gap,
    required this.horizontalInset,
    required this.canAccept,
    required this.onAcceptBefore,
    required this.onAcceptAfter,
    required this.child,
  });

  final bool enabled;
  final double gap;
  final double horizontalInset;
  final bool Function(T data) canAccept;
  final void Function(T data) onAcceptBefore;
  final void Function(T data) onAcceptAfter;
  final Widget child;

  @override
  State<_ReorderTarget<T>> createState() => _ReorderTargetState<T>();
}

class _ReorderTargetState<T extends Object> extends State<_ReorderTarget<T>> {
  bool _insertAfter = false;

  bool _isAfter(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return _insertAfter;
    return box.globalToLocal(global).dy > box.size.height / 2;
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.gap <= 0
        ? widget.child
        : Padding(
            padding: EdgeInsets.only(top: widget.gap),
            child: widget.child,
          );
    if (!widget.enabled) return content;
    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => widget.canAccept(details.data),
      onMove: (details) {
        final after = _isAfter(details.offset);
        if (after != _insertAfter) setState(() => _insertAfter = after);
      },
      onLeave: (_) {
        if (_insertAfter) setState(() => _insertAfter = false);
      },
      onAcceptWithDetails: (details) {
        final after = _isAfter(details.offset);
        setState(() => _insertAfter = false);
        if (after) {
          widget.onAcceptAfter(details.data);
        } else {
          widget.onAcceptBefore(details.data);
        }
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return Stack(
          children: [
            content,
            if (highlight)
              Positioned(
                top: _insertAfter ? null : 0,
                bottom: _insertAfter ? 0 : null,
                left: widget.horizontalInset,
                right: widget.horizontalInset,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.primary,
                  child: const SizedBox(height: 2),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.volume,
    required this.model,
    required this.chapterCount,
    required this.siblingIds,
    required this.canManage,
    required this.showDragHandle,
    required this.isFirst,
    required this.onToggle,
    required this.onChapterAppended,
  });

  final WritingCategory volume;
  final LibraryViewModel model;
  final int chapterCount;
  final List<String> siblingIds;
  final bool canManage;
  final bool showDragHandle;
  final bool isFirst;
  final VoidCallback onToggle;
  final Future<void> Function() onChapterAppended;

  Future<void> _openMenu(BuildContext context, {RelativeRect? position}) async {
    if (!canManage) return;
    final actionId = await showSidebarLibraryMenu(
      context,
      actions: volumeMenuActions(context.l10n),
      position: position,
    );
    if (actionId == null || !context.mounted) return;
    await handleVolumeMenuAction(
      context,
      model: model,
      volume: volume,
      actionId: actionId,
    );
    if (actionId == 'appendChapter') await onChapterAppended();
  }

  Future<void> _acceptVolumeDrop(
    _VolumeDragData data, {
    required bool insertAfter,
  }) async {
    if (!showDragHandle) return;
    final ids = _reorderSiblingIds(
      siblingIds: siblingIds,
      draggedId: data.volumeId,
      targetId: volume.id,
      insertAfter: insertAfter,
    );
    if (ids == null) return;
    await model.reorderVolumes(ids);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = context.zephyrSidebarItemBorderRadius;
    final listInset = context.zephyrSidebarItemInset;
    final volumeGap = context.zephyrSidebarVolumeGap;
    final compact = ZephyrBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: listInset),
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: context.zephyrOutlineSide(),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onToggle,
          onLongPress: compact && !showDragHandle
              ? () => _openMenu(context)
              : null,
          onSecondaryTapDown: !compact
              ? (details) => _openMenu(
                  context,
                  position: secondaryMenuPosition(context, details),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              9,
              showDragHandle ? _SidebarDragHandle.trailingInset : 8,
              9,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  model.isVolumeExpanded(volume.id)
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(volume.name, style: theme.textTheme.titleSmall),
                ),
                Text(
                  '$chapterCount',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (showDragHandle) ...[
                  const SizedBox(width: 4),
                  _SidebarDragHandle<_VolumeDragData>(
                    data: _VolumeDragData(volume.id),
                    feedbackLabel: volume.name,
                    onDragStarted: model.beginVolumeReorderDrag,
                    onDragEnded: model.endVolumeReorderDrag,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return _ReorderTarget<_VolumeDragData>(
      enabled: showDragHandle,
      gap: isFirst ? 0 : volumeGap,
      horizontalInset: listInset,
      canAccept: (data) => data.volumeId != volume.id,
      onAcceptBefore: (data) => _acceptVolumeDrop(data, insertAfter: false),
      onAcceptAfter: (data) => _acceptVolumeDrop(data, insertAfter: true),
      child: body,
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.model,
    required this.siblingIds,
    required this.canManage,
    required this.showDragHandle,
    required this.isFirst,
    this.aiContextEnabled = false,
    this.aiContext,
  });

  static const _lineGap = 2.0;
  static const _previewDateGap = 4.0;
  static const _textHeight = 1.15;

  final ArticleSummary chapter;
  final LibraryViewModel model;
  final List<String> siblingIds;
  final bool canManage;
  final bool showDragHandle;
  final bool isFirst;
  final bool aiContextEnabled;
  final WorkspaceAiContextSelection? aiContext;

  Future<void> _openMenu(BuildContext context, {RelativeRect? position}) async {
    if (!canManage) return;
    final actionId = await showSidebarLibraryMenu(
      context,
      actions: chapterMenuActions(context.l10n),
      position: position,
    );
    if (actionId == null || !context.mounted) return;
    await handleChapterMenuAction(
      context,
      model: model,
      chapter: chapter,
      actionId: actionId,
    );
  }

  Future<void> _acceptChapterDrop(
    _ChapterDragData data, {
    required bool insertAfter,
  }) async {
    if (!showDragHandle || data.categoryId != chapter.categoryId) return;
    final ids = _reorderSiblingIds(
      siblingIds: siblingIds,
      draggedId: data.articleId,
      targetId: chapter.id,
      insertAfter: insertAfter,
    );
    if (ids == null) return;
    await model.reorderChapters(volumeId: chapter.categoryId, orderedIds: ids);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final radius = context.zephyrSidebarItemBorderRadius;
    final showDetails =
        ZephyrScope.maybeOf(context)?.theme.ui.showChapterDetails ?? true;
    final compact = ZephyrBreakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
    final activeArticle = model.article?.id == chapter.id
        ? model.article
        : null;
    final selected = activeArticle != null;
    final preview = showDetails
        ? chapter.summary
              .replaceAll(RegExp(r'[\r\n]+'), ' ')
              .replaceAll('\u3000', '')
              .trim()
        : '';
    final title = chapter.title.isEmpty ? l10n.untitled : chapter.title;
    final listInset = context.zephyrSidebarItemInset;
    final divider = isFirst
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: listInset),
            child: ColoredBox(
              color: theme.colorScheme.outlineVariant,
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          );
    final body = Padding(
      padding: EdgeInsets.symmetric(horizontal: listInset),
      child: Material(
        color: selected
            ? theme.colorScheme.secondaryContainer.withValues(alpha: .42)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            model.selectArticle(chapter.id);
            final dualDrawer = ZephyrDualEditorPager.drawerMaybeOf(context);
            if (dualDrawer != null) {
              dualDrawer.close();
              return;
            }
            final swipe = ZephyrSwipeDrawer.maybeOf(context);
            if (swipe != null) {
              swipe.close();
              return;
            }
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              scaffold.closeDrawer();
            }
          },
          onLongPress: compact && !showDragHandle
              ? () => _openMenu(context)
              : null,
          onSecondaryTapDown: !compact
              ? (details) => _openMenu(
                  context,
                  position: secondaryMenuPosition(context, details),
                )
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              showDragHandle ? _SidebarDragHandle.trailingInset : 12,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (aiContextEnabled && aiContext != null)
                  ListenableBuilder(
                    listenable: aiContext!,
                    builder: (context, _) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Checkbox(
                        value: aiContext!.contains(chapter.id),
                        onChanged: (_) =>
                            aiContext!.toggle(chapter, displayTitle: title),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: _textHeight,
                        ),
                      ),
                      if (showDetails) ...[
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: _lineGap),
                          Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              height: _textHeight,
                            ),
                          ),
                          const SizedBox(height: _previewDateGap),
                        ] else
                          const SizedBox(height: _lineGap),
                        Text(
                          l10n.chapterMeta(
                            _formatDate(chapter.createdAt),
                            _formatDate(
                              activeArticle?.updatedAt ?? chapter.updatedAt,
                            ),
                            activeArticle?.wordCount ?? chapter.wordCount,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            height: _textHeight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 8, height: 8),
                  ),
                ],
                if (showDragHandle) ...[
                  const SizedBox(width: 4),
                  _SidebarDragHandle<_ChapterDragData>(
                    data: _ChapterDragData(
                      articleId: chapter.id,
                      categoryId: chapter.categoryId,
                    ),
                    feedbackLabel: title,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return _ReorderTarget<_ChapterDragData>(
      enabled: showDragHandle,
      gap: 0,
      horizontalInset: listInset,
      canAccept: (data) =>
          data.articleId != chapter.id && data.categoryId == chapter.categoryId,
      onAcceptBefore: (data) => _acceptChapterDrop(data, insertAfter: false),
      onAcceptAfter: (data) => _acceptChapterDrop(data, insertAfter: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [?divider, body],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _SidebarDragHandle<T extends Object> extends StatelessWidget {
  const _SidebarDragHandle({
    required this.data,
    required this.feedbackLabel,
    this.onDragStarted,
    this.onDragEnded,
  });

  /// Right inset shared by volume and chapter rows so handles align.
  static const double trailingInset = 8;
  static const double _iconSize = 18;

  final T data;
  final String feedbackLabel;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = Icon(
      Icons.drag_indicator,
      size: _iconSize,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Draggable<T>(
      data: data,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: onDragEnded == null ? null : (_) => onDragEnded!(),
      feedback: Material(
        elevation: 4,
        borderRadius: context.zephyrSidebarItemBorderRadius,
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(feedbackLabel, style: theme.textTheme.labelLarge),
        ),
      ),
      childWhenDragging: Icon(
        Icons.drag_indicator,
        size: _iconSize,
        color: theme.colorScheme.outline,
      ),
      child: handle,
    );
  }
}

/// Metrics shared with the floating desktop settings panel.
abstract final class WorkspaceLibraryDockMetrics {
  static const dockHeight = 52.0;
  static const horizontalInset = 10.0;
  static const settingsGap = 8.0;
  static const padTop = 10.0;
  static const padBottom = 12.0;
  static const overlayExtent = padTop + dockHeight + padBottom;

  static double overlayExtentFor(BuildContext context) =>
      overlayExtent + MediaQuery.viewPaddingOf(context).bottom;

  /// Distance from the workspace bottom to the top edge of the dock chrome.
  static double chromeTopInsetFromBottom(BuildContext context) =>
      dockHeight + padBottom + MediaQuery.viewPaddingOf(context).bottom;

  static double settingsBottomInset(BuildContext context) =>
      chromeTopInsetFromBottom(context) + settingsGap;
}

class _LibraryDock extends StatelessWidget {
  const _LibraryDock({
    required this.model,
    required this.openLibrary,
    required this.openSettings,
  });

  static const dockHeight = WorkspaceLibraryDockMetrics.dockHeight;
  static const horizontalInset = WorkspaceLibraryDockMetrics.horizontalInset;
  static const _padTop = WorkspaceLibraryDockMetrics.padTop;
  static const _padBottom = WorkspaceLibraryDockMetrics.padBottom;

  /// Dock height plus optional system gesture / home-indicator inset.
  static double overlayExtentFor(BuildContext context) =>
      WorkspaceLibraryDockMetrics.overlayExtentFor(context);

  final LibraryViewModel model;
  final Future<void> Function() openLibrary;
  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final radius = context.zephyrBarBorderRadius;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        _padTop,
        horizontalInset,
        _padBottom + bottomSafe,
      ),
      child: LibrarySwitcherMenu(
        model: model,
        onChooseDirectory: openLibrary,
        child: ZephyrFloatingChrome(
          borderRadius: radius,
          child: SizedBox(
            height: dockHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: LibrarySwitcherButton(model: model)),
                Tooltip(
                  message: l10n.tooltipSettings,
                  child: InkWell(
                    onTap: openSettings,
                    child: const SizedBox(
                      width: 48,
                      child: Center(child: Icon(Icons.settings_outlined)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarResizeHandle extends StatefulWidget {
  const SidebarResizeHandle({
    super.key,
    required this.model,
    required this.maxWidth,
  });

  static const width = ZephyrResizeHandle.width;

  final LibraryViewModel model;
  final double maxWidth;

  @override
  State<SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<SidebarResizeHandle> {
  /// Width at drag start — pair with cumulative dx so clamping does not
  /// desync the pointer from the sidebar edge.
  double _widthAtDragStart = 0;

  @override
  Widget build(BuildContext context) => ZephyrResizeHandle(
    onDragStart: () {
      _widthAtDragStart = widget.model.sidebarWidth;
      widget.model.setSidebarResizing(true);
    },
    onDragUpdate: (dxFromOrigin) => widget.model.resizeSidebar(
      (_widthAtDragStart + dxFromOrigin).clamp(
        LibraryViewModel.minSidebarWidth,
        widget.maxWidth,
      ),
    ),
    onDragEnd: () => widget.model.setSidebarResizing(false),
    onDragCancel: () => widget.model.setSidebarResizing(false),
  );
}
