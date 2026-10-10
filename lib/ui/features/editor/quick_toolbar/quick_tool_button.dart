import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/quick_toolbar_config.dart';
import '../../../core/zephyr_controls.dart';

/// Icon or phrase chip for the IME quick toolbar.
///
/// Ink paints on the parent [QuickToolbarBar] [Material] so the splash can
/// spread onto neighboring buttons horizontally, while the bar clips it
/// vertically. Hit targets stay the chip size.
class QuickToolButton extends StatelessWidget {
  const QuickToolButton({
    super.key,
    required this.tool,
    required this.foreground,
    required this.onPressed,
    this.enabled = true,
    this.selected = false,
    this.panelOpen = false,
    this.tooltip,
    this.bodyFontFamily,
  });

  final QuickTool tool;
  final Color foreground;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool selected;

  /// Tools panel open state — drives a +45° icon spin (no selected fill).
  final bool panelOpen;
  final String? tooltip;

  /// Article body font; used for non-symbol phrase chips.
  final String? bodyFontFamily;

  static const double height = 32;
  static const double iconExtent = 32;
  static const double iconSize = 18;
  static const double phraseFontSize = 12;
  static const double symbolFontSize = 15;

  /// Circular ink diameter is [1.5 * height]; bar Material clips top/bottom.
  static const double splashRadius = height * 0.75;

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
      QuickToolKind.tools => _ToolsPanelButton(
        open: panelOpen,
        foreground: color,
        onPressed: enabled ? onPressed : null,
      ),
      _ => _ToolbarInk(
        onTap: enabled ? onPressed : null,
        selected: selected,
        selectedColor: foreground.withValues(alpha: 0.12),
        width: iconExtent,
        child: Icon(_iconFor(tool.kind), size: iconSize, color: color),
      ),
    };
    if (tooltip == null || tool.kind == QuickToolKind.phrase) return child;
    return Tooltip(message: tooltip!, child: child);
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

/// Tools button: each open/close adds +45° (same direction). The apps glyph
/// is 90°-symmetric, so close lands looking like the resting icon again.
///
/// Ink stays on this outer shell so panel open/close rebuilds do not cancel
/// the splash; only the icon child animates.
class _ToolsPanelButton extends StatelessWidget {
  const _ToolsPanelButton({
    required this.open,
    required this.foreground,
    required this.onPressed,
  });

  final bool open;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _ToolbarInk(
      onTap: onPressed,
      width: QuickToolButton.iconExtent,
      child: _ToolsIconSpin(
        key: const ValueKey<String>('tools_icon_spin'),
        open: open,
        foreground: foreground,
      ),
    );
  }
}

class _ToolsIconSpin extends StatefulWidget {
  const _ToolsIconSpin({
    super.key,
    required this.open,
    required this.foreground,
  });

  final bool open;
  final Color foreground;

  @override
  State<_ToolsIconSpin> createState() => _ToolsIconSpinState();
}

class _ToolsIconSpinState extends State<_ToolsIconSpin> {
  static const _stepTurns = 0.125; // 45°
  static const _duration = Duration(milliseconds: 600);

  /// Increments on every open/close; drives a fresh tween via [ValueKey].
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    // Match current panel state without playing an intro spin.
    _steps = widget.open ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant _ToolsIconSpin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      setState(() => _steps += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final begin = math.max(0, _steps - 1) * _stepTurns;
    final end = _steps * _stepTurns;
    return TweenAnimationBuilder<double>(
      // New key → always runs begin→end; survives parent rebuilds cleanly.
      key: ValueKey<int>(_steps),
      tween: Tween<double>(begin: begin, end: end),
      duration: _duration,
      // Soft overshoot, then settle.
      curve: const Cubic(0.22, 1.35, 0.36, 1),
      builder: (context, turns, child) {
        return Transform.rotate(
          angle: turns * 2 * math.pi,
          child: child,
        );
      },
      child: Icon(
        Icons.apps_rounded,
        size: QuickToolButton.iconSize,
        color: widget.foreground,
      ),
    );
  }
}

/// InkResponse without its own [Material] — uses the toolbar bar Material.
class _ToolbarInk extends StatelessWidget {
  const _ToolbarInk({
    required this.onTap,
    required this.child,
    this.selected = false,
    this.selectedColor,
    this.width,
    this.padding = EdgeInsets.zero,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool selected;
  final Color? selectedColor;
  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Black bar: theme splash is often dark and nearly invisible — use a
    // light ink so the ripple reads clearly on every chip.
    final ink = Colors.white;
    return SizedBox(
      width: width,
      height: QuickToolButton.height,
      child: InkResponse(
        onTap: onTap,
        // Splash draws on the ancestor Material (the bar), not clipped to
        // this chip — so it can cover neighbors; the bar clips vertically.
        containedInkWell: false,
        highlightShape: BoxShape.circle,
        radius: QuickToolButton.splashRadius,
        splashFactory: InkRipple.splashFactory,
        splashColor: ink.withValues(alpha: 0.28),
        highlightColor: ink.withValues(alpha: 0.12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? selectedColor : null,
            borderRadius: BorderRadius.circular(
              ZephyrControls.defaultCornerRadius,
            ),
          ),
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
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
      child: _ToolbarInk(
        onTap: onPressed,
        selected: selected,
        selectedColor: foreground.withValues(alpha: 0.12),
        width: symbol ? QuickToolButton.iconExtent : null,
        padding: EdgeInsets.symmetric(horizontal: symbol ? 0 : 10),
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
    );
  }
}
