import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline chapter reference inside the AI composer.
class AiComposerArticleRef {
  const AiComposerArticleRef({required this.articleId, required this.title});

  final String articleId;
  final String title;
}

/// One [kObjectChar] per chapter in the editing buffer (atomic for caret + delete).
abstract final class AiComposerTokens {
  static const String kObjectChar = '\uFFFC';

  static bool isObjectChar(String text, int index) {
    return index >= 0 &&
        index < text.length &&
        text.codeUnitAt(index) == kObjectChar.codeUnitAt(0);
  }

  static int countIn(String text, [int start = 0, int? end]) {
    final last = end ?? text.length;
    var count = 0;
    for (var i = start; i < last && i < text.length; i++) {
      if (isObjectChar(text, i)) count++;
    }
    return count;
  }
}

/// Maps object-char offsets in the buffer to chapter metadata.
class AiComposerTokenCatalog {
  final Map<int, AiComposerArticleRef> _at = {};

  AiComposerArticleRef? at(int offset) => _at[offset];

  Iterable<AiComposerArticleRef> refsInTextOrder(String text) sync* {
    for (var i = 0; i < text.length; i++) {
      if (!AiComposerTokens.isObjectChar(text, i)) continue;
      final ref = _at[i];
      if (ref != null) yield ref;
    }
  }

  void assignFromTextOrder(String text, List<AiComposerArticleRef> refs) {
    _at.clear();
    var ri = 0;
    for (var i = 0; i < text.length && ri < refs.length; i++) {
      if (AiComposerTokens.isObjectChar(text, i)) {
        _at[i] = refs[ri++];
      }
    }
  }

  List<AiComposerArticleRef> snapshotRefsInOrder(String text) {
    return refsInTextOrder(text).toList(growable: false);
  }

  void reconcile(String oldText, String newText) {
    final refs = snapshotRefsInOrder(oldText);
    assignFromTextOrder(newText, refs);
  }

  void clear() => _at.clear();
}

/// Deletes a chapter token as one character. Caret offsets stay on either side.
class AiComposerTokenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      final collapsed = _deleteObjectChar(oldValue, newValue);
      if (collapsed != null) return collapsed;
    }
    return newValue;
  }

  TextEditingValue? _deleteObjectChar(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    final removed = oldText.length - newText.length;
    if (removed <= 0) return null;

    final changeStart = newValue.selection.start;
    final changeEnd = changeStart + removed;

    for (var i = 0; i < oldText.length; i++) {
      if (!AiComposerTokens.isObjectChar(oldText, i)) continue;
      if (changeStart <= i && i < changeEnd) {
        final without = oldText.replaceRange(i, i + 1, '');
        final caret = changeStart.clamp(0, without.length);
        return TextEditingValue(
          text: without,
          selection: TextSelection.collapsed(offset: caret),
        );
      }
    }
    return null;
  }
}

/// Renders object chars as inline capsules while editing.
class AiComposerTextEditingController extends TextEditingController {
  AiComposerTextEditingController({
    required AiComposerTokenCatalog catalog,
    Color? capsuleFill,
    Color? capsuleForeground,
  }) : catalog = catalog,
       _capsuleFill = capsuleFill,
       _capsuleForeground = capsuleForeground;

  final AiComposerTokenCatalog catalog;
  Color? _capsuleFill;
  Color? _capsuleForeground;

  void updateCapsuleColors({Color? fill, Color? foreground}) {
    _capsuleFill = fill;
    _capsuleForeground = foreground;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fill = _capsuleFill ?? scheme.secondaryContainer;
    final fg = _capsuleForeground ?? scheme.onSecondaryContainer;
    final base = style ?? DefaultTextStyle.of(context).style;

    final children = <InlineSpan>[];
    final raw = text;
    var plainStart = 0;
    for (var i = 0; i < raw.length; i++) {
      if (!AiComposerTokens.isObjectChar(raw, i)) continue;
      if (i > plainStart) {
        children.add(TextSpan(text: raw.substring(plainStart, i), style: base));
      }
      final ref = catalog.at(i);
      children.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _AiComposerCapsule(
            title: ref?.title ?? '',
            fill: fill,
            foreground: fg,
            textStyle: base,
          ),
        ),
      );
      plainStart = i + 1;
    }
    if (plainStart < raw.length) {
      children.add(TextSpan(text: raw.substring(plainStart), style: base));
    }
    if (children.isEmpty) return TextSpan(text: raw, style: base);
    return TextSpan(style: base, children: children);
  }
}

class _AiComposerCapsule extends StatelessWidget {
  const _AiComposerCapsule({
    required this.title,
    required this.fill,
    required this.foreground,
    required this.textStyle,
  });

  final String title;
  final Color fill;
  final Color foreground;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final fontSize = textStyle.fontSize ?? 16;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.45,
            vertical: 1,
          ),
          child: Text(
            title,
            style: textStyle.copyWith(
              color: foreground,
              backgroundColor: null,
              height: 1.15,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-field AI composer: text and chapter capsules share one line flow.
class WorkspaceAiComposerController extends ChangeNotifier {
  WorkspaceAiComposerController() : focusNode = FocusNode() {
    catalog = AiComposerTokenCatalog();
    text = AiComposerTextEditingController(catalog: catalog);
    text.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
    _lastText = text.text;
  }

  late final AiComposerTokenCatalog catalog;
  late final AiComposerTextEditingController text;
  final FocusNode focusNode;

  String _lastText = '';

  VoidCallback? onTextFocusChanged;

  bool containsArticle(String articleId) {
    return catalog
        .refsInTextOrder(text.text)
        .any((r) => r.articleId == articleId);
  }

  bool get isEmpty {
    if (text.text.contains(AiComposerTokens.kObjectChar)) return false;
    return text.text.trim().isEmpty;
  }

  void insertArticleAtFocus(String articleId, String title) {
    final value = text.value;
    final sel = value.selection;
    final start = sel.start.clamp(0, value.text.length);
    final end = sel.end.clamp(0, value.text.length);

    final refs = [...catalog.snapshotRefsInOrder(value.text)];
    final insertIndex = AiComposerTokens.countIn(value.text, 0, start);
    refs.insert(
      insertIndex,
      AiComposerArticleRef(articleId: articleId, title: title),
    );

    final nextText = value.text.replaceRange(
      start,
      end,
      AiComposerTokens.kObjectChar,
    );
    catalog.assignFromTextOrder(nextText, refs);
    _lastText = nextText;

    text.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    _scheduleFocus();
    notifyListeners();
  }

  void removeAllArticles(String articleId) {
    final buffer = StringBuffer();
    final refs = <AiComposerArticleRef>[];
    final raw = text.text;
    for (var i = 0; i < raw.length; i++) {
      if (AiComposerTokens.isObjectChar(raw, i)) {
        final ref = catalog.at(i);
        if (ref != null && ref.articleId == articleId) continue;
        if (ref != null) refs.add(ref);
        buffer.write(AiComposerTokens.kObjectChar);
      } else {
        buffer.write(raw[i]);
      }
    }
    final next = buffer.toString();
    if (next == raw) return;
    catalog.assignFromTextOrder(next, refs);
    text.text = next;
    _lastText = next;
    notifyListeners();
  }

  void clear() {
    text.clear();
    catalog.clear();
    _lastText = '';
    notifyListeners();
  }

  FocusNode get activeFocusNode => focusNode;

  bool hasTextFocus() => focusNode.hasFocus;

  String composeDisplayText() {
    return _composeDisplayFromBuffer(text.text, catalog).trim();
  }

  static String _composeDisplayFromBuffer(
    String raw,
    AiComposerTokenCatalog catalog,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (AiComposerTokens.isObjectChar(raw, i)) {
        final ref = catalog.at(i);
        if (ref != null) buffer.write('「${ref.title}」');
      } else {
        buffer.write(raw[i]);
      }
    }
    return buffer.toString();
  }

  List<AiComposerArticleRef> orderedArticles() {
    return catalog.refsInTextOrder(text.text).toList(growable: false);
  }

  @override
  void dispose() {
    text.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newText = text.text;
    if (newText == _lastText) {
      notifyListeners();
      return;
    }
    catalog.reconcile(_lastText, newText);
    _lastText = newText;
    notifyListeners();
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) onTextFocusChanged?.call();
  }

  void _scheduleFocus() {
    void apply() {
      if (!focusNode.canRequestFocus) return;
      focusNode.requestFocus();
    }

    apply();
    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
  }
}

/// Builds the user message body sent to the LLM, expanding chapters in order.
Future<String> composeLlmUserMessage({
  required WorkspaceAiComposerController composer,
  required Future<String> Function(String articleId, String title)
  loadChapterBlock,
}) async {
  final raw = composer.text.text;
  final catalog = composer.catalog;
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (AiComposerTokens.isObjectChar(raw, i)) {
      final ref = catalog.at(i);
      if (ref == null) continue;
      final block = await loadChapterBlock(ref.articleId, ref.title);
      buffer.write('\n\n$block\n\n');
    } else {
      buffer.write(raw[i]);
    }
  }
  return buffer.toString().trim();
}
