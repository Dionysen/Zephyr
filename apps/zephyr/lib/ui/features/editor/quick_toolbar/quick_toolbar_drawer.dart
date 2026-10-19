import 'package:flutter/material.dart';

import '../../../../domain/models/editor_preferences.dart';
import '../../../core/zephyr_l10n.dart';
import '../view_models/editor_preferences_view_model.dart';
import 'quick_toolbar_bar.dart';

/// Tools panel that occupies the soft-keyboard region while opened.
///
/// Shows live editor-style sliders (line height, paragraph gap, margins, font
/// size) plus a link to rearrange the quick toolbar.
class QuickToolbarDrawer extends StatelessWidget {
  const QuickToolbarDrawer({
    super.key,
    required this.height,
    required this.foreground,
    required this.editorPreferences,
    required this.onEditToolbar,
  });

  final double height;
  final Color foreground;
  final EditorPreferencesViewModel editorPreferences;
  final VoidCallback onEditToolbar;

  /// Side inset so slider thumbs stay clear of system edge gestures.
  static const double sliderEdgeInset = 28;

  @override
  Widget build(BuildContext context) {
    final chrome = quickToolbarForegroundOf(context, foreground);
    final muted = chrome.withValues(alpha: 0.7);
    return Material(
      color: quickToolbarBackgroundOf(context),
      // Absorb taps/drags on empty gaps so they do not fall through to the
      // editor (which would re-show the IME / feel like a dismiss).
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onEditToolbar,
                  icon: Icon(Icons.edit_outlined, size: 18, color: chrome),
                  label: Text(
                    context.l10n.quickToolbarEdit,
                    style: TextStyle(color: chrome),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: chrome,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: editorPreferences,
                  builder: (context, _) {
                    final l10n = context.l10n;
                    final prefs = editorPreferences.preferences;
                    final defaults = EditorPreferences.defaults;
                    String defaultCaption(double v, int digits, String suffix) =>
                        '（${l10n.numberPickerDefaultLabel('${v.toStringAsFixed(digits)}$suffix')}）';
                    // Five equal rows fill the remaining panel height.
                    final rows = <Widget>[
                      _StyleSliderRow(
                        label: l10n.editorLineHeightTitle,
                        defaultCaption: defaultCaption(
                          defaults.lineHeight,
                          2,
                          '×',
                        ),
                        value: prefs.lineHeight,
                        min: 1.2,
                        max: 2.4,
                        suffix: '×',
                        fractionDigits: 2,
                        chrome: chrome,
                        muted: muted,
                        onChanged: editorPreferences.updateLineHeight,
                      ),
                      _StyleSliderRow(
                        label: l10n.editorParagraphSpacingTitle,
                        defaultCaption: defaultCaption(
                          defaults.paragraphSpacing,
                          2,
                          '×',
                        ),
                        value: prefs.paragraphSpacing,
                        min: 0,
                        max: 2.5,
                        suffix: '×',
                        fractionDigits: 2,
                        chrome: chrome,
                        muted: muted,
                        onChanged: editorPreferences.updateParagraphSpacing,
                      ),
                      _StyleSliderRow(
                        label: l10n.editorMarginLeftTitle,
                        defaultCaption: defaultCaption(
                          defaults.marginLeft,
                          0,
                          'px',
                        ),
                        value: prefs.marginLeft,
                        min: EditorPreferences.minMargin,
                        max: EditorPreferences.maxMargin,
                        suffix: 'px',
                        fractionDigits: 0,
                        divisions: EditorPreferences.maxMargin.toInt(),
                        chrome: chrome,
                        muted: muted,
                        onChanged: editorPreferences.updateMarginLeft,
                      ),
                      _StyleSliderRow(
                        label: l10n.editorMarginRightTitle,
                        defaultCaption: defaultCaption(
                          defaults.marginRight,
                          0,
                          'px',
                        ),
                        value: prefs.marginRight,
                        min: EditorPreferences.minMargin,
                        max: EditorPreferences.maxMargin,
                        suffix: 'px',
                        fractionDigits: 0,
                        divisions: EditorPreferences.maxMargin.toInt(),
                        chrome: chrome,
                        muted: muted,
                        onChanged: editorPreferences.updateMarginRight,
                      ),
                      _StyleSliderRow(
                        label: l10n.editorFontSizeTitle,
                        defaultCaption: defaultCaption(
                          defaults.fontSize,
                          0,
                          'px',
                        ),
                        value: prefs.fontSize,
                        min: 12,
                        max: 32,
                        suffix: 'px',
                        fractionDigits: 0,
                        divisions: 20,
                        chrome: chrome,
                        muted: muted,
                        onChanged: editorPreferences.updateFontSize,
                      ),
                    ];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        sliderEdgeInset,
                        0,
                        sliderEdgeInset,
                        22,
                      ),
                      child: Column(
                        children: [
                          for (final row in rows)
                            Expanded(
                              // Extra vertical room falls below each compact
                              // row → larger gaps between items.
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: row,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleSliderRow extends StatefulWidget {
  const _StyleSliderRow({
    required this.label,
    required this.defaultCaption,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.fractionDigits,
    required this.chrome,
    required this.muted,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String defaultCaption;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final int fractionDigits;
  final int? divisions;
  final Color chrome;
  final Color muted;
  final ValueChanged<double> onChanged;

  @override
  State<_StyleSliderRow> createState() => _StyleSliderRowState();
}

class _StyleSliderRowState extends State<_StyleSliderRow> {
  static const _sliderPadding = 4.0;
  static const _baseThumbRadius = 7.0;
  static const _pressDuration = Duration(milliseconds: 140);

  var _dragging = false;

  void _onDragStart(double _) => setState(() => _dragging = true);

  void _onDragEnd(double _) => setState(() => _dragging = false);

  String _readout(double v) =>
      '${v.toStringAsFixed(widget.fractionDigits)}${widget.suffix}';

  @override
  Widget build(BuildContext context) {
    final clamped = widget.value.clamp(widget.min, widget.max);
    final readout = _readout(clamped);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: _dragging ? 1.0 : 0.0),
      duration: _pressDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final thumbRadius = _baseThumbRadius + 4 * t;
        final trackHeight = 2.5 + 1.5 * t;
        return SizedBox(
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        TextSpan(
                          style: TextStyle(
                            color: widget.chrome,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(text: widget.label),
                            TextSpan(
                              text: widget.defaultCaption,
                              style: TextStyle(
                                color: widget.muted,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      readout,
                      style: TextStyle(
                        color: widget.muted,
                        fontSize: 12,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: Listener(
                  onPointerUp: (_) {
                    if (_dragging) setState(() => _dragging = false);
                  },
                  onPointerCancel: (_) {
                    if (_dragging) setState(() => _dragging = false);
                  },
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: widget.chrome.withValues(alpha: 0.85),
                      inactiveTrackColor: widget.chrome.withValues(alpha: 0.22),
                      thumbColor: widget.chrome,
                      overlayColor:
                          widget.chrome.withValues(alpha: 0.08 + 0.1 * t),
                      trackHeight: trackHeight,
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 12 + 10 * t,
                      ),
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: thumbRadius,
                        elevation: 1 + 2 * t,
                      ),
                    ),
                    child: Slider(
                      value: clamped.toDouble(),
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      padding: const EdgeInsets.fromLTRB(
                        _sliderPadding,
                        0,
                        _sliderPadding,
                        0,
                      ),
                      onChanged: widget.onChanged,
                      onChangeStart: _onDragStart,
                      onChangeEnd: _onDragEnd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
