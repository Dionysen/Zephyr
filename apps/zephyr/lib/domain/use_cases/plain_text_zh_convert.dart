import 'package:opencc/opencc.dart';

/// Lazy OpenCC converters for simplified ↔ traditional Chinese.
final class PlainTextZhConverter {
  PlainTextZhConverter._();

  static ZhConverter? _s2t;
  static ZhConverter? _t2s;

  static String simplifiedToTraditional(String text) {
    _s2t ??= ZhConverter('s2t');
    return _s2t!.convert(text);
  }

  static String traditionalToSimplified(String text) {
    _t2s ??= ZhConverter('t2s');
    return _t2s!.convert(text);
  }
}
