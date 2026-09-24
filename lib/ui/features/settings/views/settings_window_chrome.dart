import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../view_models/theme_view_model.dart';

/// Keeps the native window backdrop aligned with the active writing-shell theme.
class SettingsWindowChrome extends StatefulWidget {
  const SettingsWindowChrome({
    super.key,
    required this.viewModel,
    required this.child,
  });

  final ThemeViewModel viewModel;
  final Widget child;

  @override
  State<SettingsWindowChrome> createState() => _SettingsWindowChromeState();
}

class _SettingsWindowChromeState extends State<SettingsWindowChrome> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_syncNativeBackground);
    unawaited(_syncNativeBackground());
  }

  @override
  void didUpdateWidget(covariant SettingsWindowChrome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncNativeBackground);
      widget.viewModel.addListener(_syncNativeBackground);
      unawaited(_syncNativeBackground());
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncNativeBackground);
    super.dispose();
  }

  Future<void> _syncNativeBackground() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    try {
      await windowManager.setBackgroundColor(
        Color(widget.viewModel.tokens.editorSurface),
      );
    } on Object {
      // Native chrome is optional when plugins are unavailable.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
