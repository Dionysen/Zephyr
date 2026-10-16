import 'package:flutter/material.dart';

import '../../../../domain/models/llm_settings.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../settings/models/llm_thinking_labels.dart';

/// Model picker, then thinking-level picker (both modal bottom sheets / dialogs).
Future<void> showWorkspaceAiChatModelAndThinkingSheets(
  BuildContext context, {
  required FocusNode inputFocus,
}) async {
  final l10n = context.l10n;
  final vm = ZephyrScope.of(context).llmSettings;
  final prefs = vm.preferences;
  final models = prefs.verifiedModelIds;
  if (models.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.aiChatSessionOptionsNeedTest)),
    );
    return;
  }

  _dismissComposerIme(inputFocus);
  try {
    final chosenModel = await showZephyrSettingsChoicePicker<String>(
      context,
      title: l10n.llmModelTitle,
      selected: prefs.effectiveChatModelId.isEmpty
          ? null
          : prefs.effectiveChatModelId,
      choices: [
        for (final id in models) ZephyrSettingsChoice(value: id, label: id),
      ],
    );
    if (!context.mounted || chosenModel == null) return;

    if (chosenModel == prefs.selectedModelId) {
      await vm.setChatModelId('');
    } else {
      await vm.setChatModelId(chosenModel);
    }
    if (!context.mounted) return;

    final afterModel = vm.preferences;
    final thinkingLevels = afterModel.allowThinking
        ? kLlmSelectableThinkingLevels
        : const [LlmThinkingLevel.off];

    final modelLabel = afterModel.effectiveChatModelId.isEmpty
        ? chosenModel
        : afterModel.effectiveChatModelId;

    final chosenThinking =
        await showZephyrSettingsChoicePicker<LlmThinkingLevel>(
      context,
      title: l10n.llmThinkingLevelTitle,
      subtitle: l10n.aiChatThinkingForModel(modelLabel),
      selected: afterModel.chatThinkingLevel,
      choices: [
        for (final level in thinkingLevels)
          ZephyrSettingsChoice(
            value: level,
            label: llmThinkingLevelLabel(level, l10n),
          ),
      ],
    );
    if (!context.mounted || chosenThinking == null) return;
    if (afterModel.allowThinking || chosenThinking == LlmThinkingLevel.off) {
      await vm.setChatThinkingLevel(chosenThinking);
    }
  } finally {
    if (context.mounted) {
      _restoreComposerIme(inputFocus);
    }
  }
}

void _dismissComposerIme(FocusNode inputFocus) {
  if (inputFocus.hasFocus) {
    inputFocus.unfocus();
    return;
  }
  final primary = FocusManager.instance.primaryFocus;
  if (primary != null && primary.hasFocus) {
    primary.unfocus();
  }
}

void _restoreComposerIme(FocusNode inputFocus) {
  void refocus() {
    if (inputFocus.canRequestFocus) {
      inputFocus.requestFocus();
    }
  }

  refocus();
  WidgetsBinding.instance.addPostFrameCallback((_) => refocus());
}
