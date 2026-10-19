import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/ui_preferences.dart';

/// Sidebar volume/chapter corner radius when the user has never customized it.
double defaultSidebarItemCornerRadiusForPlatform() {
  if (kIsWeb) return UiPreferences.defaults.cornerRadius;
  if (Platform.isAndroid || Platform.isIOS) return 0;
  return UiPreferences.defaults.cornerRadius;
}
