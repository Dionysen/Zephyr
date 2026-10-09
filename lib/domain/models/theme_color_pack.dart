import 'theme_tokens.dart';

/// A named color palette (built-in or user-saved) for light/dark mode slots.
class ThemeColorPack {
  const ThemeColorPack({
    required this.id,
    required this.name,
    required this.tokens,
    this.builtInPreset,
  });

  factory ThemeColorPack.builtIn(ThemePreset preset) => ThemeColorPack(
    id: builtInId(preset),
    name: preset.name,
    tokens: ThemeTokens.presets[preset]!,
    builtInPreset: preset,
  );

  final String id;
  final String name;
  final ThemeTokens tokens;
  final ThemePreset? builtInPreset;

  bool get isBuiltIn => builtInPreset != null;

  static String builtInId(ThemePreset preset) => preset.name;

  static List<ThemeColorPack> get builtIns => [
    for (final preset in ThemePreset.values) ThemeColorPack.builtIn(preset),
  ];

  ThemeColorPack copyWith({
    String? id,
    String? name,
    ThemeTokens? tokens,
    ThemePreset? builtInPreset,
  }) => ThemeColorPack(
    id: id ?? this.id,
    name: name ?? this.name,
    tokens: tokens ?? this.tokens,
    builtInPreset: builtInPreset ?? this.builtInPreset,
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeColorPack &&
      id == other.id &&
      name == other.name &&
      tokens == other.tokens &&
      builtInPreset == other.builtInPreset;

  @override
  int get hashCode => Object.hash(id, name, tokens, builtInPreset);
}
