import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Intercepts platform close gestures and keeps the settings engine alive.
class SettingsWindowShell extends StatefulWidget {
  const SettingsWindowShell({
    super.key,
    required this.windowId,
    required this.child,
  });

  final int windowId;
  final Widget child;

  @override
  State<SettingsWindowShell> createState() => _SettingsWindowShellState();
}

class _SettingsWindowShellState extends State<SettingsWindowShell>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_hide());
  }

  Future<void> _hide() =>
      WindowController.fromWindowId(widget.windowId).hide();

  @override
  Widget build(BuildContext context) => widget.child;
}
