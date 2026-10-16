import 'package:flutter/material.dart';

import '../models/workspace_ai_composer_document.dart';

/// Single multiline field with inline chapter capsules (same flow as plain text).
class WorkspaceAiChatComposerField extends StatelessWidget {
  const WorkspaceAiChatComposerField({
    super.key,
    required this.composer,
    required this.hintText,
    required this.style,
    required this.hintStyle,
    this.maxLines = 6,
  });

  final WorkspaceAiComposerController composer;
  final String hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    composer.text.updateCapsuleColors(
      fill: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
    );

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
}
