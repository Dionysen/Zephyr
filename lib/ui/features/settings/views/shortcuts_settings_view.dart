import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../../domain/use_cases/shortcut_resolver.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_settings.dart';
import '../models/shortcut_labels.dart';
import '../view_models/keyboard_shortcuts_view_model.dart';

class ShortcutsSettingsView extends StatelessWidget {
  const ShortcutsSettingsView({
    super.key,
    required this.viewModel,
    this.compact = false,
  });

  final KeyboardShortcutsViewModel viewModel;
  final bool compact;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final l10n = context.l10n;
      final children = <Widget>[
        for (final group in ShortcutGroup.values) ...[
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.shortcutGroupTitle(group),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          if (compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
              child: Text(
                l10n.shortcutGroupTitle(group),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ZephyrSettingsSection(
            children: [
              for (final (i, id) in actionsInGroup(group).indexed)
                ZephyrSettingsListTile(
                  title: l10n.shortcutActionTitle(id),
                  subtitle: viewModel.chordsFor(id).isEmpty
                      ? l10n.shortcutsUnbound
                      : viewModel.labelFor(id),
                  showDivider: i < actionsInGroup(group).length - 1,
                  onTap: () => _record(context, id),
                  onLongPress: () => viewModel.resetAction(id),
                  trailing: IconButton(
                    tooltip: l10n.shortcutsResetAction,
                    icon: const Icon(Icons.restart_alt, size: 20),
                    onPressed: () => viewModel.resetAction(id),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: viewModel.resetAll,
            child: Text(l10n.shortcutsResetAll),
          ),
        ),
      ];

      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: children,
      );
    },
  );

  Future<void> _record(BuildContext context, ShortcutActionId id) async {
    final l10n = context.l10n;
    final result = await showDialog<_RecordResult>(
      context: context,
      builder: (context) => _ShortcutRecordDialog(
        title: l10n.shortcutsRecordTitle,
        hint: l10n.shortcutsRecordHint,
        apple: viewModel.isApple,
      ),
    );
    if (!context.mounted || result == null) return;
    if (result.clear) {
      viewModel.clearAction(id);
      return;
    }
    final chord = result.chord;
    if (chord == null) return;
    viewModel.assignChord(id, chord);
    if (viewModel.lastDisplaced.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shortcutsConflictHint)),
      );
    }
  }
}

class _RecordResult {
  const _RecordResult.chord(this.chord) : clear = false;
  const _RecordResult.clear() : chord = null, clear = true;

  final KeyChord? chord;
  final bool clear;
}

class _ShortcutRecordDialog extends StatefulWidget {
  const _ShortcutRecordDialog({
    required this.title,
    required this.hint,
    required this.apple,
  });

  final String title;
  final String hint;
  final bool apple;

  @override
  State<_ShortcutRecordDialog> createState() => _ShortcutRecordDialogState();
}

class _ShortcutRecordDialogState extends State<_ShortcutRecordDialog> {
  String? _preview;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.backspace &&
            !HardwareKeyboard.instance.isControlPressed &&
            !HardwareKeyboard.instance.isMetaPressed &&
            !HardwareKeyboard.instance.isAltPressed &&
            !HardwareKeyboard.instance.isShiftPressed) {
          Navigator.of(context).pop(const _RecordResult.clear());
          return KeyEventResult.handled;
        }
        // Ignore bare modifier keys.
        if (key == LogicalKeyboardKey.shift ||
            key == LogicalKeyboardKey.shiftLeft ||
            key == LogicalKeyboardKey.shiftRight ||
            key == LogicalKeyboardKey.control ||
            key == LogicalKeyboardKey.controlLeft ||
            key == LogicalKeyboardKey.controlRight ||
            key == LogicalKeyboardKey.meta ||
            key == LogicalKeyboardKey.metaLeft ||
            key == LogicalKeyboardKey.metaRight ||
            key == LogicalKeyboardKey.alt ||
            key == LogicalKeyboardKey.altLeft ||
            key == LogicalKeyboardKey.altRight) {
          return KeyEventResult.handled;
        }
        final chord = chordFromKeyEvent(event);
        setState(() {
          _preview = formatKeyChord(chord, apple: widget.apple);
        });
        Navigator.of(context).pop(_RecordResult.chord(chord));
        return KeyEventResult.handled;
      },
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hint),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              Text(
                _preview!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}
