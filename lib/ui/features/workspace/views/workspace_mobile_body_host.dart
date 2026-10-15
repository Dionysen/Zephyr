import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/zephyr_scope.dart';
import '../../../core/zephyr_swipe_drawer.dart';
import '../../editor/view_models/library_view_model.dart';
import 'workspace_sidebar.dart';

/// Compact workspace body: wakelock, startup chrome, drawer after book switch.
class WorkspaceMobileBodyHost extends StatefulWidget {
  const WorkspaceMobileBodyHost({
    super.key,
    required this.model,
    required this.child,
  });

  final LibraryViewModel model;
  final Widget child;

  @override
  State<WorkspaceMobileBodyHost> createState() => _WorkspaceMobileBodyHostState();
}

class _WorkspaceMobileBodyHostState extends State<WorkspaceMobileBodyHost> {
  var _startupChromeApplied = false;
  String? _trackedBookId;
  bool? _wakelockEnabled;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onLibraryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyStartupChrome();
      _trackedBookId = widget.model.selectedBook?.id;
    });
  }

  @override
  void dispose() {
    widget.model.removeListener(_onLibraryChanged);
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _onLibraryChanged() {
    if (!_startupChromeApplied && widget.model.library != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_applyStartupChrome());
      });
    }
    final bookId = widget.model.selectedBook?.id;
    if (_trackedBookId == null) {
      _trackedBookId = bookId;
      return;
    }
    if (bookId == _trackedBookId) return;
    _trackedBookId = bookId;
    final ui = ZephyrScope.of(context).theme.ui;
    if (!ui.openSidebarAfterBookSwitch) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ZephyrSwipeDrawer.of(context).open();
    });
  }

  Future<void> _applyStartupChrome() async {
    if (!mounted || _startupChromeApplied || widget.model.library == null) {
      return;
    }
    _startupChromeApplied = true;
    final ui = ZephyrScope.of(context).theme.ui;
    if (ui.openBookListOnStartup) {
      await showWorkspaceMobileBookSheet(context, model: widget.model);
      if (!mounted) return;
      if (ui.openSidebarOnStartup) {
        ZephyrSwipeDrawer.of(context).open();
      }
      return;
    }
    if (ui.openSidebarOnStartup) {
      ZephyrSwipeDrawer.of(context).open();
    }
  }

  void _syncWakelock(bool enabled) {
    if (enabled) {
      unawaited(WakelockPlus.enable());
    } else {
      unawaited(WakelockPlus.disable());
    }
  }

  @override
  Widget build(BuildContext context) {
    final keepOn = ZephyrScope.of(context).theme.ui.keepScreenOn;
    if (_wakelockEnabled != keepOn) {
      _wakelockEnabled = keepOn;
      _syncWakelock(keepOn);
    }
    return widget.child;
  }
}
