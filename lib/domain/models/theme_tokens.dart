/// Semantic color roles used by the writing shell.
///
/// Values are opaque ARGB integers so this model stays independent from
/// Flutter's rendering library and can be stored by any platform adapter.
enum ThemeToken {
  editorSurface,
  sidebarSurface,
  controlSurface,
  border,
  primaryText,
  mutedText,
  accent,
}

class ThemeTokens {
  const ThemeTokens({
    required this.editorSurface,
    required this.sidebarSurface,
    required this.controlSurface,
    required this.border,
    required this.primaryText,
    required this.mutedText,
    required this.accent,
  });

  static const defaults = ThemeTokens(
    editorSurface: 0xFF1E1E1E,
    sidebarSurface: 0xFF171717,
    controlSurface: 0xFF242424,
    border: 0xFF343434,
    primaryText: 0xFFE8E8E8,
    mutedText: 0xFF858585,
    accent: 0xFF9ACBA7,
  );

  final int editorSurface;
  final int sidebarSurface;
  final int controlSurface;
  final int border;
  final int primaryText;
  final int mutedText;
  final int accent;

  int valueOf(ThemeToken token) => switch (token) {
    ThemeToken.editorSurface => editorSurface,
    ThemeToken.sidebarSurface => sidebarSurface,
    ThemeToken.controlSurface => controlSurface,
    ThemeToken.border => border,
    ThemeToken.primaryText => primaryText,
    ThemeToken.mutedText => mutedText,
    ThemeToken.accent => accent,
  };

  ThemeTokens withValue(ThemeToken token, int value) => switch (token) {
    ThemeToken.editorSurface => copyWith(editorSurface: value),
    ThemeToken.sidebarSurface => copyWith(sidebarSurface: value),
    ThemeToken.controlSurface => copyWith(controlSurface: value),
    ThemeToken.border => copyWith(border: value),
    ThemeToken.primaryText => copyWith(primaryText: value),
    ThemeToken.mutedText => copyWith(mutedText: value),
    ThemeToken.accent => copyWith(accent: value),
  };

  ThemeTokens copyWith({
    int? editorSurface,
    int? sidebarSurface,
    int? controlSurface,
    int? border,
    int? primaryText,
    int? mutedText,
    int? accent,
  }) => ThemeTokens(
    editorSurface: editorSurface ?? this.editorSurface,
    sidebarSurface: sidebarSurface ?? this.sidebarSurface,
    controlSurface: controlSurface ?? this.controlSurface,
    border: border ?? this.border,
    primaryText: primaryText ?? this.primaryText,
    mutedText: mutedText ?? this.mutedText,
    accent: accent ?? this.accent,
  );
}
