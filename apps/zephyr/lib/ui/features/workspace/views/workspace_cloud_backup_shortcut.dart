import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../domain/models/keyboard_shortcuts.dart';
import '../../../core/zephyr_scope.dart';
import 'cloud_backup_quick_button.dart';

/// Handles the configurable cloud-backup chord when focus is outside the body
/// editor (e.g. chapter title).
KeyEventResult? handleCloudBackupShortcut(BuildContext context, KeyEvent event) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
    return null;
  }
  final action =
      ZephyrScope.of(context).keyboardShortcuts.actionForKeyEvent(event);
  if (action != ShortcutActionId.cloudBackupNow) return null;
  if (event is KeyDownEvent) {
    unawaited(runCloudBackupNow(context));
  }
  return KeyEventResult.handled;
}
