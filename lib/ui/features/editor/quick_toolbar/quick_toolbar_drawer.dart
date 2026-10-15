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
                  // Five equal rows fill the remaining panel height.
                  final rows = <Widget>[
                    _StyleSliderRow(
                      label: l10n.editorLineHeightTitle,
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
    );
  }
}

class _StyleSliderRow extends StatelessWidget {
  const _StyleSliderRow({
    required this.label,
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
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final readout =
        '${clamped.toStringAsFixed(fractionDigits)}$suffix';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chrome,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ),
            Text(
              readout,
              style: TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ],
        ),
        // Tight title → track gap; item-to-item spacing comes from the
        // Expanded slots in the parent column.
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: chrome.withValues(alpha: 0.85),
            inactiveTrackColor: chrome.withValues(alpha: 0.22),
            thumbColor: chrome,
            overlayColor: chrome.withValues(alpha: 0.12),
            trackHeight: 2.5,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: clamped.toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            // Keep thumbs clear of system edge gestures.
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
