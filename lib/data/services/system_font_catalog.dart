import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/models/editor_preferences.dart';

/// macOS font registry (Core Text / Font Book), including collection (.ttc)
/// files the directory scanner would miss.
class SystemFontCatalog {
  SystemFontCatalog({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('zephyr/system_fonts');

  final MethodChannel _channel;

  Future<List<SystemFont>> listFonts() async {
    if (!Platform.isMacOS) {
      return const [];
    }
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('listFonts');
      if (raw == null) {
        return const [];
      }
      return [
            for (final item in raw)
              if (item is Map)
                SystemFont(
                  family: item['family'] as String? ?? '',
                  path: item['path'] as String? ?? '',
                ),
          ]
          .where((font) => font.family.isNotEmpty && font.path.isNotEmpty)
          .toList();
    } on Object {
      return const [];
    }
  }
}
