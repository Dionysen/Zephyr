import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_controls.dart';

/// Icon or phrase chip for the IME quick toolbar.
class QuickToolButton extends StatelessWidget {
  const QuickToolButton({
    super.key,
    required this.tool,
    required this.foreground,
    required this.onPressed,
    this.enabled = true,
    this.selected = false,
    this.tooltip,
    this.bodyFontFamily,
  });

  final QuickTool tool;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool selected;
  final String? tooltip;

  /// Article body font; used for non-symbol phrase chips.
  final String? bodyFontFamily;

  static const double height = 32;
  static const double iconExtent = 32;
  static const double iconSize = 18;
  static const double phraseFontSize = 12;
  static const double symbolFontSize = 15;

  @override
  Widget build(BuildContext context) {
    final color = foreground.withValues(alpha: enabled ? 1 : 0.35);
    final child = switch (tool.kind) {
      QuickToolKind.phrase => _PhraseChip(
        label: (tool.label?.trim().isNotEmpty ?? false)
            ? tool.label!.trim()
            : (tool.payload ?? ''),
        foreground: color,
        selected: selected,
        onPressed: enabled ? onPressed : null,
        fontFamily: bodyFontFamily,
      ),
      _ => SizedBox(
        width: iconExtent,
        height: height,
        child: IconButton(
          onPressed: enabled ? onPressed : null,
          tooltip: tooltip,
          style: IconButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color,
            backgroundColor: selected
                ? foreground.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: ZephyrControls.iconButtonShape,
            padding: EdgeInsets.zero,
          ),
          icon: Icon(_iconFor(tool.kind), size: iconSize),
        ),
      ),
    };
    if (tooltip == null || tool.kind == QuickToolKind.phrase) return child;
    return child;
  }

  static IconData _iconFor(QuickToolKind kind) => switch (kind) {
    QuickToolKind.tools => Icons.apps_rounded,
    QuickToolKind.undo => Icons.undo_rounded,
    QuickToolKind.paste => Icons.content_paste_rounded,
    QuickToolKind.indent => Icons.format_indent_increase_rounded,
    QuickToolKind.format => Icons.auto_fix_high_rounded,
    QuickToolKind.phrase => Icons.short_text_rounded,
  };
}

/// Short punctuation / symbol labels (quotes, dashes, brackets, …).
bool quickToolbarLabelLooksLikeSymbol(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  final graphemes = trimmed.characters;
  if (graphemes.length > 2) return false;
  // Letters / numbers (incl. CJK) → normal phrase chip.
  return !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(trimmed);
}

/// Chip-only: map fullwidth ASCII punctuation to proportional glyphs so a
/// pair still fits a square. Insert payload is unchanged.
String compactSymbolChipLabel(String label) {
  const map = {
    '（': '(',
    '）': ')',
    '［': '[',
    '］': ']',
    '｛': '{',
    '｝': '}',
  };
  return label.characters.map((g) => map[g] ?? g).join();
}

class _PhraseChip extends StatelessWidget {
  const _PhraseChip({
    required this.label,
    required this.foreground,
    required this.selected,
    required this.onPressed,
    this.fontFamily,
  });

  final String label;
  final Color foreground;
  final bool selected;
  final VoidCallback? onPressed;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final symbol = quickToolbarLabelLooksLikeSymbol(label);
    final display = symbol ? compactSymbolChipLabel(label) : label;
    // Symbol chips stay 32×32. Use the platform UI sans (proportional
    // punctuation) instead of the article CJK font.
    final style = TextStyle(
      fontFamily: symbol ? null : fontFamily,
      fontFamilyFallback: symbol
          ? const ['Roboto', 'Segoe UI', 'sans-serif']
          : null,
      fontSize: symbol
          ? QuickToolButton.symbolFontSize
          : QuickToolButton.phraseFontSize,
      height: 1,
      color: foreground,
      fontFeatures: symbol
          ? const [
              FontFeature.enable('palt'),
              FontFeature.enable('halt'),
              FontFeature.enable('pwid'),
            ]
          : null,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: symbol ? 0 : 2),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: foreground,
          backgroundColor: selected
              ? foreground.withValues(alpha: 0.12)
              : Colors.transparent,
          minimumSize: Size(
            symbol ? QuickToolButton.iconExtent : 0,
            QuickToolButton.height,
          ),
          maximumSize: symbol
              ? const Size(QuickToolButton.iconExtent, QuickToolButton.height)
              : null,
          padding: EdgeInsets.symmetric(horizontal: symbol ? 0 : 10),
          shape: ZephyrControls.labeledButtonShape,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Align(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}
