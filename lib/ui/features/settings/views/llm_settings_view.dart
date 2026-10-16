import 'package:flutter/material.dart';

import '../../../../domain/llm/llm_provider_catalog.dart';
import '../../../../domain/models/llm_settings.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_settings.dart';
import '../../../core/zephyr_status_bar.dart';
import '../../../core/zephyr_snackbar.dart';
import '../view_models/llm_settings_view_model.dart';

class LlmSettingsPage extends StatefulWidget {
  const LlmSettingsPage({super.key});

  static Route<void> route() => MaterialPageRoute<void>(
    builder: (_) => const LlmSettingsPage(),
  );

  @override
  State<LlmSettingsPage> createState() => _LlmSettingsPageState();
}

class _LlmSettingsPageState extends State<LlmSettingsPage> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  var _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController.addListener(_onApiKeyEdited);
    _baseUrlController.addListener(_onBaseUrlEdited);
  }

  @override
  void dispose() {
    _apiKeyController
      ..removeListener(_onApiKeyEdited)
      ..dispose();
    _baseUrlController
      ..removeListener(_onBaseUrlEdited)
      ..dispose();
    super.dispose();
  }

  void _onApiKeyEdited() {
    ZephyrScope.of(context).llmSettings.setApiKey(_apiKeyController.text);
  }

  void _onBaseUrlEdited() {
    ZephyrScope.of(context).llmSettings.setCustomBaseUrl(_baseUrlController.text);
  }

  String _providerLabel(LlmProviderKind kind, AppLocalizations l10n) {
    final zh = l10n.localeName.startsWith('zh');
    return zh ? LlmProviderCatalog.labelZh(kind) : LlmProviderCatalog.labelEn(kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = ZephyrScope.of(context).llmSettings;
    final surface = Theme.of(context).colorScheme.surface;
    final barColor = ZephyrSettingsAppBar.backgroundColor(context);

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        if (_apiKeyController.text != vm.apiKey) {
          _apiKeyController.text = vm.apiKey;
        }
        if (_baseUrlController.text != vm.preferences.customBaseUrl) {
          _baseUrlController.text = vm.preferences.customBaseUrl;
        }
        final prefs = vm.preferences;
        final showCustomUrl =
            prefs.provider == LlmProviderKind.openAiCompatible;
        final models = prefs.verifiedModelIds;

        return ColoredBox(
          color: surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: barColor,
                child: ZephyrTopSafeArea(
                  bottom: false,
                  child: ZephyrSettingsAppBar(
                    title: l10n.llmSettingsTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      l10n.llmSettingsIntro,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _test(LlmSettingsViewModel vm, AppLocalizations l10n) async {
    await vm.testConnection();
    if (!mounted) return;
    if (vm.error == null && vm.preferences.hasVerifiedModels) {
      ZephyrSnackBar.show(context, l10n.llmTestSuccess(vm.preferences.verifiedModelIds.length));
    }
  }
}
