import '../../domain/models/editor_preferences.dart';
import '../../domain/repositories/editor_preferences_repository.dart';
import '../services/editor_preferences_file_storage.dart';

class FileEditorPreferencesRepository implements EditorPreferencesRepository {
  FileEditorPreferencesRepository(this._storage);
  final EditorPreferencesFileStorage _storage;

  @override
  Future<EditorPreferences> load() async {
    final values = await _storage.read();
    if (values == null) return EditorPreferences.defaults;
    final defaults = EditorPreferences.defaults;
    final fontSize = _double(values, 'fontSize');
    final fontPath = values['fontPath'] as String?;
    final fontFamily = values['fontFamily'] as String?;
    return EditorPreferences(
      // Null family with no custom path → bundled default (霞鹜文楷).
      fontFamily: fontFamily ??
          (fontPath == null ? defaults.fontFamily : null),
      fontPath: fontPath,
      fontSize: fontSize,
      lineHeight: _double(values, 'lineHeight'),
      paragraphSpacing: _paragraphSpacingMultiplier(
        _double(values, 'paragraphSpacing'),
        fontSize,
      ),
      firstLineIndent: _int(values, 'firstLineIndent'),
      marginLeft: _optionalDouble(values, 'marginLeft') ?? defaults.marginLeft,
      marginRight:
          _optionalDouble(values, 'marginRight') ?? defaults.marginRight,
      editorWidth:
          _optionalDouble(values, 'editorWidth') ?? defaults.editorWidth,
      titleFontSize: _optionalDouble(values, 'titleFontSize') ??
          defaults.titleFontSize,
      titleCentered:
          _optionalBool(values, 'titleCentered') ?? defaults.titleCentered,
      typewriterMode: _optionalBool(values, 'typewriterMode') ??
          _optionalBool(values, 'typingMode') ??
          defaults.typewriterMode,
      jumpToEndOnScrollDown: _optionalBool(values, 'jumpToEndOnScrollDown') ??
          defaults.jumpToEndOnScrollDown,
    );
  }

  /// Legacy builds stored paragraph spacing in pixels (0–32). Multipliers are
  /// typically 0–2.5; convert old pixel values using the saved font size.
  double _paragraphSpacingMultiplier(double value, double fontSize) {
    if (value <= 3) return value;
    if (fontSize <= 0) return EditorPreferences.defaults.paragraphSpacing;
    return (value / fontSize).clamp(0.0, 2.5);
  }

  @override
  Future<void> save(EditorPreferences value) => _storage.write({
    'fontFamily': value.fontFamily,
    'fontPath': value.fontPath,
    'fontSize': value.fontSize,
    'lineHeight': value.lineHeight,
    'paragraphSpacing': value.paragraphSpacing,
    'firstLineIndent': value.firstLineIndent,
    'marginLeft': value.marginLeft,
    'marginRight': value.marginRight,
    'editorWidth': value.editorWidth,
    'titleFontSize': value.titleFontSize,
    'titleCentered': value.titleCentered,
    'typewriterMode': value.typewriterMode,
    'jumpToEndOnScrollDown': value.jumpToEndOnScrollDown,
  });

  double _double(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! num) throw FormatException('Invalid $key preference.');
    return value.toDouble();
  }

  double? _optionalDouble(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! num) return null;
    return value.toDouble();
  }

  bool? _optionalBool(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! bool) return null;
    return value;
  }

  int _int(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is! int) throw FormatException('Invalid $key preference.');
    return value;
  }
}
