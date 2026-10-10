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
class QuickToolbarBar extends StatelessWidget {
  const QuickToolbarBar({
    super.key,
    required this.config,
    required this.foreground,
    required this.toolsDrawerOpen,
    required this.canUndo,
    required this.onToolPressed,
    this.bodyFontFamily,
  });

  final QuickToolbarConfig config;
  final Color foreground;
  final bool toolsDrawerOpen;
  final bool canUndo;
  final ValueChanged<QuickTool> onToolPressed;

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
            for (final tool in pinned)
              QuickToolButton(
                tool: tool,
                foreground: chrome,
                enabled: tool.kind != QuickToolKind.undo || canUndo,
                tooltip: _tooltip(l10n, tool),
                bodyFontFamily: bodyFontFamily,
                onPressed: () => onToolPressed(tool),
              ),
            if (custom.isNotEmpty) ...[
              _ShortDivider(color: chrome),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: custom.length,
                  itemBuilder: (context, index) {
                    final tool = custom[index];
                    return QuickToolButton(
                      tool: tool,
                      foreground: chrome,
                      enabled: tool.kind != QuickToolKind.undo || canUndo,
                      tooltip: _tooltip(l10n, tool),
                      bodyFontFamily: bodyFontFamily,
                      onPressed: () => onToolPressed(tool),
                    );
                  },
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  String? _tooltip(AppLocalizations l10n, QuickTool tool) => switch (tool.kind) {
    QuickToolKind.undo => l10n.quickToolbarUndoTooltip,
    QuickToolKind.paste => l10n.quickToolbarPasteTooltip,
    QuickToolKind.indent => l10n.quickToolbarIndentTooltip,
    QuickToolKind.format => l10n.quickToolbarFormatTooltip,
    QuickToolKind.phrase => tool.label,
    QuickToolKind.tools => l10n.quickToolbarToolsTooltip,
  };
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
