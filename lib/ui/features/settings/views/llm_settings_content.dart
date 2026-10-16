import 'package:flutter/material.dart';

import '../../../../domain/llm/llm_provider_catalog.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_snackbar.dart';
import '../models/llm_thinking_labels.dart';
import '../view_models/llm_settings_view_model.dart';

/// Model provider, API key, and chat-behavior controls (no page chrome).
class LlmSettingsContent extends StatefulWidget {
  const LlmSettingsContent({super.key, this.showIntro = true});

  final bool showIntro;

  @override
  State<LlmSettingsContent> createState() => _LlmSettingsContentState();
}

class _LlmSettingsContentState extends State<LlmSettingsContent> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _presetController = TextEditingController();
  var _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.addListener(_onApiKeyEdited);
    _baseUrlController.addListener(_onBaseUrlEdited);
    _presetController.addListener(_onPresetEdited);
  }

  @override
  void dispose() {
    _apiKeyController
      ..removeListener(_onApiKeyEdited)
      ..dispose();
    _baseUrlController
      ..removeListener(_onBaseUrlEdited)
      ..dispose();
    _presetController
      ..removeListener(_onPresetEdited)
      ..dispose();
    super.dispose();
  }

  void _onApiKeyEdited() {
    ZephyrScope.of(context).llmSettings.setApiKey(_apiKeyController.text);
  }

  void _onBaseUrlEdited() {
    ZephyrScope.of(context).llmSettings
        .setCustomBaseUrl(_baseUrlController.text);
  }

  void _onPresetEdited() {
    ZephyrScope.of(context).llmSettings
        .setPresetSystemPrompt(_presetController.text);
  }

  String _providerLabel(LlmProviderKind kind, AppLocalizations l10n) {
    final zh = l10n.localeName.startsWith('zh');
    return zh
        ? LlmProviderCatalog.labelZh(kind)
        : LlmProviderCatalog.labelEn(kind);
  }

  Future<void> _test(LlmSettingsViewModel vm, AppLocalizations l10n) async {
    await vm.testConnection();
    if (!mounted) return;
    if (vm.error == null && vm.preferences.hasVerifiedModels) {
      ZephyrSnackBar.show(
        context,
        l10n.llmTestSuccess(vm.preferences.verifiedModelIds.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = ZephyrScope.of(context).llmSettings;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (_apiKeyController.text != vm.apiKey) {
          _apiKeyController.text = vm.apiKey;
        }
        if (_baseUrlController.text != vm.preferences.customBaseUrl) {
          _baseUrlController.text = vm.preferences.customBaseUrl;
        }
        if (_presetController.text != vm.preferences.presetSystemPrompt) {
          _presetController.text = vm.preferences.presetSystemPrompt;
        }
        final prefs = vm.preferences;
        final showCustomUrl =
            prefs.provider == LlmProviderKind.openAiCompatible;
        final models = prefs.verifiedModelIds;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showIntro) ...[
              Text(
                l10n.llmSettingsIntro,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsChoiceTile<LlmProviderKind>(
                  icon: Icons.hub_outlined,
                  title: l10n.llmProviderTitle,
                  subtitle: l10n.llmProviderSubtitle,
                  selected: prefs.provider,
                  valueLabel: _providerLabel(prefs.provider, l10n),
                  choices: [
                    for (final kind in LlmProviderKind.values)
                      ZephyrSettingsChoice(
                        value: kind,
                        label: _providerLabel(kind, l10n),
                      ),
                  ],
                  onSelected: vm.setProvider,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: l10n.llmApiKeyTitle,
                      hintText: l10n.llmApiKeyHint,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCustomUrl)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _baseUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.llmBaseUrlTitle,
                        hintText: l10n.llmBaseUrlHint,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton.icon(
                    onPressed: vm.testing ? null : () => _test(vm, l10n),
                    icon: vm.testing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link_outlined),
                    label: Text(l10n.llmTestConnection),
                  ),
                ),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      vm.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (models.isNotEmpty)
                  ZephyrSettingsChoiceTile<String>(
                    icon: Icons.smart_toy_outlined,
                    title: l10n.llmModelTitle,
                    subtitle: l10n.llmModelSubtitle,
                    selected: prefs.selectedModelId,
                    valueLabel: prefs.selectedModelId.isEmpty
                        ? l10n.llmModelNotSelected
                        : prefs.selectedModelId,
                    choices: [
                      for (final id in models)
                        ZephyrSettingsChoice(value: id, label: id),
                    ],
                    onSelected: vm.selectModel,
                    showDivider: false,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.llmBehaviorSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ZephyrSettingsSection(
              children: [
                ZephyrSettingsSwitchTile(
                  icon: Icons.stream_outlined,
                  title: l10n.llmStreamOutputTitle,
                  subtitle: l10n.llmStreamOutputSubtitle,
                  value: prefs.streamOutput,
                  onChanged: vm.setStreamOutput,
                ),
                ZephyrSettingsSwitchTile(
                  icon: Icons.psychology_outlined,
                  title: l10n.llmAllowThinkingTitle,
                  subtitle: l10n.llmAllowThinkingSubtitle,
                  value: prefs.allowThinking,
                  onChanged: vm.setAllowThinking,
                ),
                if (prefs.allowThinking)
                  ZephyrSettingsChoiceTile<LlmThinkingLevel>(
                    icon: Icons.psychology_alt_outlined,
                    title: l10n.llmDefaultThinkingLevelTitle,
                    subtitle: l10n.llmDefaultThinkingLevelSubtitle,
                    selected: prefs.defaultThinkingLevel,
                    valueLabel: llmThinkingLevelLabel(
                      prefs.defaultThinkingLevel,
                      l10n,
                    ),
                    choices: [
                      for (final level in kLlmSelectableThinkingLevels)
                        ZephyrSettingsChoice(
                          value: level,
                          label: llmThinkingLevelLabel(level, l10n),
                        ),
                    ],
                    onSelected: (level) {
                      vm.setDefaultThinkingLevel(level);
                      vm.setChatThinkingLevel(level);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: TextField(
                    controller: _presetController,
                    minLines: 2,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: l10n.llmPresetPromptTitle,
                      hintText: l10n.llmPresetPromptHint,
                      helperText: l10n.llmPresetPromptDescription,
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  icon: Icons.input_outlined,
                  title: l10n.llmMaxInputTokensTitle,
                  description: l10n.llmMaxInputTokensSubtitle,
                  value: prefs.maxInputTokens.toDouble(),
                  min: 4096,
                  max: 2000000,
                  defaultValue: kLlmDefaultMaxInputTokens.toDouble(),
                  formatValue: (value) => '${value.round()}',
                  onChanged: (value) => vm.setMaxInputTokens(value.round()),
                ),
                ZephyrSettingsAdaptiveNumber(
                  compact: true,
                  icon: Icons.output_outlined,
                  title: l10n.llmMaxOutputTokensTitle,
                  description: l10n.llmMaxOutputTokensSubtitle,
                  value: prefs.maxOutputTokens.toDouble(),
                  min: 256,
                  max: 2000000,
                  defaultValue: kLlmDefaultMaxOutputTokens.toDouble(),
                  formatValue: (value) => '${value.round()}',
                  onChanged: (value) => vm.setMaxOutputTokens(value.round()),
                  showDivider: false,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
