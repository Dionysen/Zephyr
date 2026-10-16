import 'package:flutter/material.dart';

import '../../../../domain/models/llm_settings.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../settings/models/llm_thinking_labels.dart';

Future<void> showWorkspaceAiChatModelSheet(
  BuildContext context, {
  required FocusNode inputFocus,
}) async {
  final l10n = context.l10n;
  final vm = ZephyrScope.of(context).llmSettings;
  final prefs = vm.preferences;
  final chatProfile = prefs.chatProfile;
  final models = chatProfile.verifiedModelIds;
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

    if (chosenModel == chatProfile.selectedModelId) {
      await vm.setChatModelId('');
    } else {
      await vm.setChatModelId(chosenModel);
    }
  } finally {
    if (context.mounted) {
      _restoreComposerIme(inputFocus);
    }
  }
}

Future<void> showWorkspaceAiChatThinkingSheet(
  BuildContext context, {
  required FocusNode inputFocus,
}) async {
  final l10n = context.l10n;
  final vm = ZephyrScope.of(context).llmSettings;
  final prefs = vm.preferences;
  final modelId = prefs.effectiveChatModelId;
  if (modelId.isEmpty) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.llmModelNotSelected)),
    );
    return;
  }

  final thinkingLevels = prefs.allowThinking
      ? kLlmSelectableThinkingLevels
      : const [LlmThinkingLevel.off];
  final selected = prefs.resolvedChatThinkingLevel(modelId);

  _dismissComposerIme(inputFocus);
  try {
    final chosenThinking =
        await showZephyrSettingsChoicePicker<LlmThinkingLevel>(
      context,
      title: l10n.llmThinkingLevelTitle,
      subtitle: l10n.aiChatThinkingForModel(modelId),
      selected: selected,
      choices: [
        for (final level in thinkingLevels)
          ZephyrSettingsChoice(
            value: level,
            label: llmThinkingLevelLabel(level, l10n),
          ),
      ],
    );
    if (!context.mounted || chosenThinking == null) return;
    if (prefs.allowThinking || chosenThinking == LlmThinkingLevel.off) {
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
