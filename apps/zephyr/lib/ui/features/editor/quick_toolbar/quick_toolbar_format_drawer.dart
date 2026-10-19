import 'package:flutter/material.dart';

import '../../../../domain/models/plain_text_format_option.dart';
import '../../../core/zephyr_l10n.dart';
import '../view_models/quick_toolbar_view_model.dart';
import 'quick_toolbar_bar.dart';

/// Format options panel in the soft-keyboard region.
class QuickToolbarFormatDrawer extends StatelessWidget {
  const QuickToolbarFormatDrawer({
    super.key,
    required this.height,
    required this.foreground,
    required this.toolbar,
    required this.onApplyAll,
    required this.onApplyOption,
  });

  final double height;
  final Color foreground;
  final QuickToolbarViewModel toolbar;
  final VoidCallback onApplyAll;
  final ValueChanged<PlainTextFormatOption> onApplyOption;

  static const _checkboxOptions = [
    PlainTextFormatOption.keepParagraphBlanks,
    PlainTextFormatOption.removeParagraphBlanks,
    PlainTextFormatOption.insertCjkLatinSpaces,
    PlainTextFormatOption.addParagraphIndent,
    PlainTextFormatOption.removeParagraphIndent,
    PlainTextFormatOption.simplifiedToTraditional,
    PlainTextFormatOption.traditionalToSimplified,
    PlainTextFormatOption.halfwidthToFullwidth,
  ];

  @override
  Widget build(BuildContext context) {
    final chrome = quickToolbarForegroundOf(context, foreground);
    final muted = chrome.withValues(alpha: 0.7);
    final l10n = context.l10n;

    return Material(
      color: quickToolbarBackgroundOf(context),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ListenableBuilder(
          listenable: toolbar,
          builder: (context, _) {
            final liveSelection = toolbar.formatSelection;
            return ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              children: [
                _ApplyAllTile(
                  label: l10n.quickToolbarFormatApplyAll,
                  chrome: chrome,
                  onPressed: onApplyAll,
                ),
                const SizedBox(height: 4),
                for (final option in _checkboxOptions)
                  _FormatOptionTile(
                    label: _label(l10n, option),
                    chrome: chrome,
                    muted: muted,
                    checked: liveSelection.isSelected(option),
                    onCheckChanged: (on) => toolbar.setFormatOption(option, on),
                    onApply: () => onApplyOption(option),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _label(AppLocalizations l10n, PlainTextFormatOption option) {
    return switch (option) {
      PlainTextFormatOption.keepParagraphBlanks =>
        l10n.quickToolbarFormatKeepParagraphBlanks,
      PlainTextFormatOption.removeParagraphBlanks =>
        l10n.quickToolbarFormatRemoveParagraphBlanks,
      PlainTextFormatOption.insertCjkLatinSpaces =>
        l10n.quickToolbarFormatInsertCjkLatinSpaces,
      PlainTextFormatOption.addParagraphIndent =>
        l10n.quickToolbarFormatAddParagraphIndent,
      PlainTextFormatOption.removeParagraphIndent =>
        l10n.quickToolbarFormatRemoveParagraphIndent,
      PlainTextFormatOption.simplifiedToTraditional =>
        l10n.quickToolbarFormatSimplifiedToTraditional,
      PlainTextFormatOption.traditionalToSimplified =>
        l10n.quickToolbarFormatTraditionalToSimplified,
      PlainTextFormatOption.halfwidthToFullwidth =>
        l10n.quickToolbarFormatHalfwidthToFullwidth,
    };
  }
}

class _ApplyAllTile extends StatelessWidget {
  const _ApplyAllTile({
    required this.label,
    required this.chrome,
    required this.onPressed,
  });

  final String label;
  final Color chrome;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: chrome.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: chrome, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: chrome,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatOptionTile extends StatelessWidget {
  const _FormatOptionTile({
    required this.label,
    required this.chrome,
    required this.muted,
    required this.checked,
    required this.onCheckChanged,
    required this.onApply,
  });

  final String label;
  final Color chrome;
  final Color muted;
  final bool checked;
  final ValueChanged<bool> onCheckChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Checkbox(
              value: checked,
              activeColor: chrome,
              checkColor: quickToolbarBackgroundOf(context),
              side: BorderSide(color: muted),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (value) {
                if (value != null) onCheckChanged(value);
              },
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onApply,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    label,
                    style: TextStyle(color: chrome, fontSize: 14, height: 1.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
