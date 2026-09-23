import 'package:flutter/material.dart';

import '../../../../domain/models/theme_tokens.dart';
import '../view_models/theme_view_model.dart';

Future<void> showThemeSettings(
  BuildContext context,
  ThemeViewModel viewModel,
) => showDialog<void>(
  context: context,
  builder: (_) => _ThemeSettingsDialog(viewModel: viewModel),
);

class _ThemeSettingsDialog extends StatefulWidget {
  const _ThemeSettingsDialog({required this.viewModel});
  final ThemeViewModel viewModel;

  @override
  State<_ThemeSettingsDialog> createState() => _ThemeSettingsDialogState();
}

class _ThemeSettingsDialogState extends State<_ThemeSettingsDialog> {
  late final Map<ThemeToken, TextEditingController> _controllers = {
    for (final token in ThemeToken.values)
      token: TextEditingController(
        text: _hex(widget.viewModel.tokens.valueOf(token)),
      ),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme tokens',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Changes apply immediately and are saved for every library.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final token in ThemeToken.values)
                        _TokenField(
                          label: _label(token),
                          token: token,
                          controller: _controllers[token]!,
                          value: widget.viewModel.tokens.valueOf(token),
                          onChanged: (value) =>
                              widget.viewModel.update(token, value),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.viewModel.restoreDefaults();
                      for (final token in ThemeToken.values) {
                        _controllers[token]!.text = _hex(
                          widget.viewModel.tokens.valueOf(token),
                        );
                      }
                    },
                    child: const Text('Restore defaults'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TokenField extends StatelessWidget {
  const _TokenField({
    required this.label,
    required this.token,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final ThemeToken token;
  final TextEditingController controller;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Color(value),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 150, child: Text(label)),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            maxLength: 7,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '#RRGGBB',
            ),
            onChanged: (text) {
              final parsed = _parseHex(text);
              if (parsed != null) onChanged(parsed);
            },
          ),
        ),
      ],
    ),
  );
}

String _label(ThemeToken token) => switch (token) {
  ThemeToken.editorSurface => 'Editor surface',
  ThemeToken.sidebarSurface => 'Sidebar surface',
  ThemeToken.controlSurface => 'Control surface',
  ThemeToken.border => 'Border',
  ThemeToken.primaryText => 'Primary text',
  ThemeToken.mutedText => 'Muted text',
  ThemeToken.accent => 'Accent',
};

String _hex(int value) =>
    '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

int? _parseHex(String value) {
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(value.trim());
  return match == null
      ? null
      : 0xFF000000 | int.parse(match.group(1)!, radix: 16);
}
