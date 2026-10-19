import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workspace_ai_composer_document.dart';

/// Single multiline field with inline chapter capsules (same flow as plain text).
class WorkspaceAiChatComposerField extends StatelessWidget {
  const WorkspaceAiChatComposerField({
    super.key,
    required this.composer,
    required this.hintText,
    required this.style,
    required this.hintStyle,
    this.onSubmit,
    this.maxLines = 6,
  });

  final WorkspaceAiComposerController composer;
  final String hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;

  /// Desktop: Enter sends. Shift+Enter still inserts a newline.
  final VoidCallback? onSubmit;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    composer.text.updateCapsuleColors(
      fill: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
    );
    final desktop =
        Theme.of(context).platform != TargetPlatform.android &&
        Theme.of(context).platform != TargetPlatform.iOS;
    composer.focusNode.onKeyEvent = desktop && onSubmit != null
        ? _sendOnEnter
        : null;

    return TextField(
      controller: composer.text,
      focusNode: composer.focusNode,
      minLines: 1,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textAlignVertical: TextAlignVertical.top,
      style: style,
      inputFormatters: [AiComposerTokenFormatter()],
      decoration: InputDecoration(
        hintText: composer.isEmpty ? hintText : null,
        hintStyle: hintStyle,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  KeyEventResult _sendOnEnter(FocusNode node, KeyEvent event) {
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final composing = composer.text.value.composing;
    if (composing.isValid && !composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) {
      onSubmit?.call();
    }
    return KeyEventResult.handled;
  }
}
