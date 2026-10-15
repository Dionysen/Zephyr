import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_l10n.dart';
import 'quick_tool_button.dart';

const quickToolbarHeight = QuickToolButton.height;

/// Light themes: white strip; dark themes: solid black (IME accessory chrome).
Color quickToolbarBackgroundOf(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light
    ? Colors.white
    : const Color(0xFF000000);

/// Light themes: black glyphs; dark themes use the host [fallback] (usually onSurface).
Color quickToolbarForegroundOf(BuildContext context, Color fallback) =>
    Theme.of(context).brightness == Brightness.light ? Colors.black : fallback;

/// Dual-zone IME accessory: fixed (non-scroll) | custom (horizontal scroll).
///
/// Long-press any non-tools button to drag-reorder within its zone.
class QuickToolbarBar extends StatelessWidget {
  const QuickToolbarBar({
    super.key,
    required this.config,
    required this.foreground,
    required this.toolsDrawerOpen,
    required this.canUndo,
    required this.onToolPressed,
    this.onReorderPinned,
    this.onReorderCustom,
    this.bodyFontFamily,
  });

  final QuickToolbarConfig config;
  final Color foreground;
  final bool toolsDrawerOpen;
  final bool canUndo;
  final ValueChanged<QuickTool> onToolPressed;

  /// Destination index is post-removal (same as [ReorderableListView.onReorderItem]).
  final void Function(int oldIndex, int newIndex)? onReorderPinned;
  final void Function(int oldIndex, int newIndex)? onReorderCustom;

  /// Article body font for phrase chips.
  final String? bodyFontFamily;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pinned = config.pinnedTools;
    final custom = config.customTools;
    final chrome = quickToolbarForegroundOf(context, foreground);
    // Shared Material: ink spreads across sibling buttons horizontally and
    // is clipped to this strip vertically (does not spill outside the bar).
    return Material(
      color: quickToolbarBackgroundOf(context),
      child: SizedBox(
        height: quickToolbarHeight,
        child: Row(
          children: [
            QuickToolButton(
              tool: QuickTool.tools,
              foreground: chrome,
              panelOpen: toolsDrawerOpen,
              tooltip: l10n.quickToolbarToolsTooltip,
              bodyFontFamily: bodyFontFamily,
              onPressed: () => onToolPressed(QuickTool.tools),
            ),
            if (pinned.isNotEmpty)
              _ReorderableToolRow(
                tools: pinned,
                foreground: chrome,
                canUndo: canUndo,
                bodyFontFamily: bodyFontFamily,
                scrollable: false,
                onToolPressed: onToolPressed,
                onReorder: onReorderPinned,
                tooltipFor: (tool) => _tooltip(l10n, tool),
              ),
            if (custom.isNotEmpty) ...[
              _ShortDivider(color: chrome),
              Expanded(
                child: _ReorderableToolRow(
                  tools: custom,
                  foreground: chrome,
                  canUndo: canUndo,
                  bodyFontFamily: bodyFontFamily,
                  scrollable: true,
                  onToolPressed: onToolPressed,
                  onReorder: onReorderCustom,
                  tooltipFor: (tool) => _tooltip(l10n, tool),
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  String? _tooltip(AppLocalizations l10n, QuickTool tool) =>
      switch (tool.kind) {
        QuickToolKind.undo => l10n.quickToolbarUndoTooltip,
        QuickToolKind.paste => l10n.quickToolbarPasteTooltip,
        QuickToolKind.indent => l10n.quickToolbarIndentTooltip,
        QuickToolKind.format => l10n.quickToolbarFormatTooltip,
        QuickToolKind.phrase => tool.label,
        QuickToolKind.tools => l10n.quickToolbarToolsTooltip,
      };
}

class _ReorderableToolRow extends StatelessWidget {
  const _ReorderableToolRow({
    required this.tools,
    required this.foreground,
    required this.canUndo,
    required this.scrollable,
    required this.onToolPressed,
    required this.tooltipFor,
    this.bodyFontFamily,
    this.onReorder,
  });

  final List<QuickTool> tools;
  final Color foreground;
  final bool canUndo;
  final bool scrollable;
  final String? bodyFontFamily;
  final ValueChanged<QuickTool> onToolPressed;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final String? Function(QuickTool tool) tooltipFor;

  @override
  Widget build(BuildContext context) {
    if (onReorder == null) {
      final children = [
        for (final tool in tools)
          QuickToolButton(
            tool: tool,
            foreground: foreground,
            enabled: tool.kind != QuickToolKind.undo || canUndo,
            tooltip: tooltipFor(tool),
            bodyFontFamily: bodyFontFamily,
            onPressed: () => onToolPressed(tool),
          ),
      ];
      if (!scrollable) {
        return Row(mainAxisSize: MainAxisSize.min, children: children);
      }
      return ScrollConfiguration(
        behavior: const _QuickToolbarScrollBehavior(),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          children: children,
        ),
      );
    }

    final list = ReorderableListView.builder(
      scrollDirection: Axis.horizontal,
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())
          : const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: tools.length,
      onReorderItem: onReorder!,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            return Material(
              color: Colors.transparent,
              elevation: 2 + 4 * t,
              shadowColor: Colors.black54,
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final tool = tools[index];
        // No tooltip while reorder is enabled — long-press starts a drag.
        return ReorderableDelayedDragStartListener(
          key: ValueKey(tool.id),
          index: index,
          child: QuickToolButton(
            tool: tool,
            foreground: foreground,
            enabled: tool.kind != QuickToolKind.undo || canUndo,
            bodyFontFamily: bodyFontFamily,
            onPressed: () => onToolPressed(tool),
          ),
        );
      },
    );
    return scrollable
        ? ScrollConfiguration(
            behavior: const _QuickToolbarScrollBehavior(),
            child: list,
          )
        : list;
  }
}

/// Material's stretch feedback is available on every supported platform,
/// including when the custom zone is shorter than its viewport.
class _QuickToolbarScrollBehavior extends MaterialScrollBehavior {
  const _QuickToolbarScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => StretchingOverscrollIndicator(
    axisDirection: details.direction,
    child: child,
  );
}

class _ShortDivider extends StatelessWidget {
  const _ShortDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Container(
          width: 1,
          height: 20,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
