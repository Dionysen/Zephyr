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

enum ThemePreset {
  light,
  grey,
  slate,
  claude,
  mint,
  purple,
  hermes,
  ocean,
  darkModern,
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

  static const presets = <ThemePreset, ThemeTokens>{
    ThemePreset.light: ThemeTokens(
      editorSurface: 0xFFF9F9FA,
      sidebarSurface: 0xFFF1F3F6,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFE1E4E8,
      primaryText: 0xFF25272A,
      mutedText: 0xFF70757D,
      accent: 0xFF2563EB,
    ),
    ThemePreset.grey: ThemeTokens(
      editorSurface: 0xFFF8FAFC,
      sidebarSurface: 0xFFF0F3F7,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFDDE3EA,
      primaryText: 0xFF293241,
      mutedText: 0xFF718096,
      accent: 0xFF475569,
    ),
    ThemePreset.slate: ThemeTokens(
      editorSurface: 0xFFFAFAFA,
      sidebarSurface: 0xFFF3F4F6,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFE5E5E5,
      primaryText: 0xFF34343A,
      mutedText: 0xFF777780,
      accent: 0xFF4B5563,
    ),
    ThemePreset.claude: ThemeTokens(
      editorSurface: 0xFFFCFAF7,
      sidebarSurface: 0xFFF4F0E9,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFE7E0D5,
      primaryText: 0xFF39312B,
      mutedText: 0xFF82756A,
      accent: 0xFFB85C16,
    ),
    ThemePreset.mint: ThemeTokens(
      editorSurface: 0xFFFBFDFC,
      sidebarSurface: 0xFFE5F2EC,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFD2E5DC,
      primaryText: 0xFF253A32,
      mutedText: 0xFF6A8277,
      accent: 0xFF2FA36F,
    ),
    ThemePreset.purple: ThemeTokens(
      editorSurface: 0xFFFCF9FF,
      sidebarSurface: 0xFFF0E6FB,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFE5D9F2,
      primaryText: 0xFF382D4A,
      mutedText: 0xFF7E708F,
      accent: 0xFF7C3AED,
    ),
    ThemePreset.hermes: ThemeTokens(
      editorSurface: 0xFFF7F7FF,
      sidebarSurface: 0xFFE9EAFA,
      controlSurface: 0xFFFFFFFF,
      border: 0xFFDCDDFA,
      primaryText: 0xFF252D50,
      mutedText: 0xFF70769A,
      accent: 0xFF1D4ED8,
    ),
    ThemePreset.ocean: ThemeTokens(
      editorSurface: 0xFF161923,
      sidebarSurface: 0xFF10131B,
      controlSurface: 0xFF202531,
      border: 0xFF303847,
      primaryText: 0xFFE4E8F0,
      mutedText: 0xFF8B95A7,
      accent: 0xFF73A5FF,
    ),
    ThemePreset.darkModern: defaults,
  };

  final int editorSurface;
  final int sidebarSurface;
  final int controlSurface;
  final int border;
  final int primaryText;
  final int mutedText;
  final int accent;

  ThemePreset? get preset => ThemePreset.values
      .where((candidate) => presets[candidate] == this)
      .firstOrNull;

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

  @override
  bool operator ==(Object other) =>
      other is ThemeTokens &&
      editorSurface == other.editorSurface &&
      sidebarSurface == other.sidebarSurface &&
      controlSurface == other.controlSurface &&
      border == other.border &&
      primaryText == other.primaryText &&
      mutedText == other.mutedText &&
      accent == other.accent;

  @override
  int get hashCode => Object.hash(
    editorSurface,
    sidebarSurface,
    controlSurface,
    border,
    primaryText,
    mutedText,
    accent,
  );
}
