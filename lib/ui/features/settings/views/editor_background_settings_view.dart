import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../domain/models/editor_background.dart';
import '../../../../domain/models/theme_tokens.dart';
import '../../../core/editor_background_layer.dart';
import '../../../core/zephyr_bottom_sheet.dart';
import '../../../core/zephyr_l10n.dart';
import '../../../core/zephyr_theme.dart';
import '../view_models/theme_view_model.dart';

/// Horizontal inset so opacity / blur thumbs are harder to miss-drag at ends.
const double _sliderEndInset = 20;

String editorBackgroundSummary(
  AppLocalizations l10n,
  EditorBackgroundConfig config,
) {
  if (!config.hasImage) {
    return l10n.editorBackgroundNone;
  }
  final name = p.basename(config.imagePath!);
  final display = name.replaceFirst(RegExp(r'^-?\d+_'), '');
  final fit = editorBackgroundFitLabel(l10n, config.fit);
  final opacity = (config.opacity * 100).round();
  final blur = config.blurSigma.round();
  if (blur <= 0) {
    return l10n.editorBackgroundSummary(display, fit, opacity);
  }
  return l10n.editorBackgroundSummaryWithBlur(display, fit, opacity, blur);
}

String editorBackgroundFitLabel(
  AppLocalizations l10n,
  EditorBackgroundFit fit,
) => switch (fit) {
  EditorBackgroundFit.cover => l10n.editorBackgroundFitCover,
  EditorBackgroundFit.contain => l10n.editorBackgroundFitContain,
  EditorBackgroundFit.fill => l10n.editorBackgroundFitFill,
  EditorBackgroundFit.tile => l10n.editorBackgroundFitTile,
  EditorBackgroundFit.center => l10n.editorBackgroundFitCenter,
};

/// Full-page editor for one mode's writing-column background.
class EditorBackgroundSettingsView extends StatelessWidget {
  const EditorBackgroundSettingsView({
    super.key,
    required this.viewModel,
    required this.dark,
  });

  final ThemeViewModel viewModel;
  final bool dark;

  EditorBackgroundConfig get _config =>
      viewModel.editorBackground(dark: dark);

  ThemeTokens get _tokens => dark ? viewModel.darkTokens : viewModel.lightTokens;

  void _update(EditorBackgroundConfig config) {
    viewModel.updateEditorBackground(dark: dark, config: config);
  }

  Future<void> _pickImage(BuildContext context) async {
    await viewModel.loadBackgroundImages();
    if (!context.mounted) return;
    final selected = await showEditorBackgroundLibrarySheet(
      context,
      viewModel: viewModel,
      selectedPath: _config.imagePath,
    );
    if (selected == null || !context.mounted) return;
    if (selected.isEmpty) {
      viewModel.clearEditorBackground(dark: dark);
      return;
    }
    _update(
      _config.copyWith(
        imagePath: selected,
        opacity: _config.hasImage
            ? _config.opacity
            : EditorBackgroundConfig.defaultOpacity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final config = _config;
        final surface = Color(_tokens.editorSurface);
        final textColor = Color(_tokens.primaryText);
        final enabled = config.hasImage;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.zephyrCornerRadius),
              child: ColoredBox(
                color: surface,
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: EditorBackgroundLayer(
                    config: config,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          config.hasImage
                              ? l10n.editorBackgroundPreviewSample
                              : l10n.editorBackgroundNoImagePreview,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ImageRow(
              config: config,
              onChoose: () => _pickImage(context),
              onClear: enabled
                  ? () => viewModel.clearEditorBackground(dark: dark)
                  : null,
            ),
            const SizedBox(height: 12),
            _FitRow(
              enabled: enabled,
              fit: config.fit,
              onSelected: (fit) => _update(config.copyWith(fit: fit)),
            ),
            const SizedBox(height: 8),
            _SliderBlock(
              enabled: enabled,
              label: l10n.editorBackgroundOpacityTitle,
              valueLabel: '${(config.opacity * 100).round()}%',
              value: config.opacity,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: enabled
                  ? (value) => _update(config.copyWith(opacity: value))
                  : null,
            ),
            _SliderBlock(
              enabled: enabled,
              label: l10n.editorBackgroundBlurTitle,
              description: l10n.editorBackgroundBlurDescription,
              valueLabel: '${config.blurSigma.round()}',
              value: config.blurSigma,
              min: EditorBackgroundConfig.minBlurSigma,
              max: EditorBackgroundConfig.maxBlurSigma,
              divisions: EditorBackgroundConfig.maxBlurSigma.round(),
              onChanged: enabled
                  ? (value) => _update(config.copyWith(blurSigma: value))
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _ImageRow extends StatelessWidget {
  const _ImageRow({
    required this.config,
    required this.onChoose,
    required this.onClear,
  });

  final EditorBackgroundConfig config;
  final VoidCallback onChoose;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final path = config.imagePath;
    final name = path == null || path.isEmpty
        ? l10n.editorBackgroundNone
        : p.basename(path).replaceFirst(RegExp(r'^-?\d+_'), '');

    return Row(
      children: [
        _Thumb(path: path),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextButton(onPressed: onChoose, child: Text(l10n.editorBackgroundChoose)),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(l10n.editorBackgroundClear),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    Widget child;
    if (path != null && path!.isNotEmpty && File(path!).existsSync()) {
      child = Image.file(
        File(path!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      child = Icon(
        Icons.image_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: SizedBox(width: 52, height: 52, child: child),
      ),
    );
  }
}

class _FitRow extends StatelessWidget {
  const _FitRow({
    required this.enabled,
    required this.fit,
    required this.onSelected,
  });

  final bool enabled;
  final EditorBackgroundFit fit;
  final ValueChanged<EditorBackgroundFit> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.editorBackgroundFitTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            color: enabled ? null : theme.disabledColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in EditorBackgroundFit.values)
              FilterChip(
                label: Text(editorBackgroundFitLabel(l10n, value)),
                selected: fit == value,
                onSelected: enabled ? (_) => onSelected(value) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.enabled,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.description,
  });

  final bool enabled;
  final String label;
  final String? description;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = enabled ? null : theme.disabledColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(color: muted),
                ),
              ),
              Text(
                valueLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sliderEndInset),
            child: SliderTheme(
              data: theme.sliderTheme.copyWith(
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                padding: EdgeInsets.zero,
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns the chosen image path, `''` for none, or `null` if dismissed.
Future<String?> showEditorBackgroundLibrarySheet(
  BuildContext context, {
  required ThemeViewModel viewModel,
  required String? selectedPath,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.zephyrCornerRadius + 4),
      ),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => _LibraryBody(
          viewModel: viewModel,
          selectedPath: selectedPath,
          scrollController: scrollController,
        ),
      ),
    ),
  );
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.viewModel,
    required this.selectedPath,
    required this.scrollController,
  });

  final ThemeViewModel viewModel;
  final String? selectedPath;
  final ScrollController scrollController;

  Future<void> _import(BuildContext context) async {
    final l10n = context.l10n;
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    final path = file?.path;
    if (path == null || path.isEmpty) return;
    final imported = await viewModel.importBackgroundImage(path);
    if (!context.mounted) return;
    if (imported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editorBackgroundImportFailure)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.editorBackgroundImportSuccess)),
    );
    Navigator.of(context).pop(imported.path);
  }

  Future<void> _delete(BuildContext context, BackgroundImage image) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editorBackgroundDeleteTitle),
        content: Text(l10n.editorBackgroundDeleteBody(image.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await viewModel.deleteBackgroundImage(image);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? l10n.editorBackgroundDeleteSuccess
              : l10n.editorBackgroundDeleteFailure,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final images = viewModel.backgroundImages;
    final selected = selectedPath ?? '';

    return Material(
      color: theme.colorScheme.surface,
      child: ZephyrBottomSheet.listTheme(
        context: context,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          children: [
            Padding(
              padding: ZephyrBottomSheet.titlePadding,
              child: Text(
                l10n.editorBackgroundSelectTitle,
                style: ZephyrBottomSheet.titleStyle(theme),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.add_photo_alternate_outlined,
                size: ZephyrBottomSheet.rowIconSize,
              ),
              title: Text(l10n.editorBackgroundAddFromFile),
              onTap: () => _import(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                selected.isEmpty
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: ZephyrBottomSheet.rowIconSize,
                color: selected.isEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(l10n.editorBackgroundNone),
              onTap: () => Navigator.of(context).pop(''),
            ),
            if (viewModel.isLoadingBackgroundImages)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (images.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  l10n.editorBackgroundEmptyLibrary,
                  style: ZephyrBottomSheet.bodyStyle(theme),
                ),
              )
            else
              for (final image in images)
                ListTile(
                  leading: Icon(
                    selected == image.path
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: ZephyrBottomSheet.rowIconSize,
                    color: selected == image.path
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(image.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Thumb(path: image.path),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.actionDelete,
                        onPressed: () => _delete(context, image),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(image.path),
                ),
          ],
        ),
      ),
    );
  }
}
