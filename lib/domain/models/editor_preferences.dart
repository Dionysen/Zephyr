import 'zephyr_bundled_fonts.dart';

class EditorPreferences {
  const EditorPreferences({
    required this.fontFamily,
    required this.fontPath,
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.marginLeft,
    required this.marginRight,
    required this.editorWidth,
    required this.titleFontSize,
    required this.titleCentered,
    required this.typewriterMode,
  });

  static const defaults = EditorPreferences(
    fontFamily: ZephyrBundledFonts.wenkaiLite,
    fontPath: null,
    fontSize: 15,
    lineHeight: 1.80,
    paragraphSpacing: 0.85,
    firstLineIndent: 2,
    marginLeft: 19,
    marginRight: 15,
    editorWidth: 720,
    titleFontSize: 25,
    titleCentered: true,
    typewriterMode: false,
  );

  static const minTitleFontSize = 14.0;
  static const maxTitleFontSize = 48.0;
  static const minMargin = 0.0;
  static const maxMargin = 120.0;
  static const minEditorWidth = 320.0;
  static const maxEditorWidth = 1200.0;

  final String? fontFamily;

  /// A durable system font identity. The font family is local to one Flutter
  /// engine after [SystemFontRepository.loadFont] registers it.
  final String? fontPath;
  final double fontSize;

  /// Line-height multiplier for wrapping lines inside a paragraph.
  final double lineHeight;

  /// Gap between paragraphs as a font-size multiplier (block padding).
  final double paragraphSpacing;
  final int firstLineIndent;

  /// Preferred left inset of the reading column (px). May shrink proportionally
  /// with [marginRight] when the viewport is too narrow.
  /// Used on compact / mobile layouts.
  final double marginLeft;

  /// Preferred right inset of the reading column (px).
  /// Used on compact / mobile layouts.
  final double marginRight;

  /// Preferred reading-column width on desktop (px), always centered.
  final double editorWidth;

  /// Chapter title block above the writing column.
  final double titleFontSize;

  /// When true, title text is centered in the reading column; otherwise
  /// left-aligned to the same edge as the body.
  final bool titleCentered;

  /// When true, keeps the caret line vertically centered, dims paragraphs
  /// other than the caret's, and dims the chapter title while it is unfocused.
  final bool typewriterMode;

  EditorPreferences copyWith({
    String? fontFamily,
    String? fontPath,
    bool clearFontFamily = false,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    int? firstLineIndent,
    double? marginLeft,
    double? marginRight,
    double? editorWidth,
    double? titleFontSize,
    bool? titleCentered,
    bool? typewriterMode,
  }) => EditorPreferences(
    fontFamily: clearFontFamily
        ? ZephyrBundledFonts.wenkaiLite
        : fontFamily ?? this.fontFamily,
    fontPath: clearFontFamily ? null : fontPath ?? this.fontPath,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    firstLineIndent: firstLineIndent ?? this.firstLineIndent,
    marginLeft: marginLeft ?? this.marginLeft,
    marginRight: marginRight ?? this.marginRight,
    editorWidth: editorWidth ?? this.editorWidth,
    titleFontSize: titleFontSize ?? this.titleFontSize,
    titleCentered: titleCentered ?? this.titleCentered,
    typewriterMode: typewriterMode ?? this.typewriterMode,
  );
}

class SystemFont {
  const SystemFont({
    required this.family,
    required this.path,
    this.imported = false,
  });
  final String family;
  final String path;

  /// True when the file lives in the app-owned fonts directory (can be deleted).
  final bool imported;

  @override
  bool operator ==(Object other) => other is SystemFont && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
