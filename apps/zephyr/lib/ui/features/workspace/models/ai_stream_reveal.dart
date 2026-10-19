import 'dart:async';

/// Reveals streamed assistant text one grapheme at a time.
///
/// Arrival gaps set the pace so a burst is spread across the time the model
/// actually took to produce it, instead of painting the whole token at once.
class AiStreamReveal {
  String _text = '';
  String _thinking = '';
  int _textShown = 0;
  int _thinkingShown = 0;
  var thinkingInProgress = false;

  DateTime? _lastArrival;
  double _gapMs = 36;

  Completer<void>? _caughtUp;

  String get visibleText => _slice(_text, _textShown);

  String get visibleThinking => _slice(_thinking, _thinkingShown);

  bool get thinkingCaughtUp => _thinkingShown >= _thinking.runes.length;

  bool get isCaughtUp => thinkingCaughtUp && _textShown >= _text.runes.length;

  int get backlog =>
      (_thinking.runes.length - _thinkingShown) +
      (_text.runes.length - _textShown);

  void reset() {
    _text = '';
    _thinking = '';
    _textShown = 0;
    _thinkingShown = 0;
    thinkingInProgress = false;
    _lastArrival = null;
    _gapMs = 36;
    if (_caughtUp != null && !_caughtUp!.isCompleted) {
      _caughtUp!.complete();
    }
    _caughtUp = null;
  }

  void setTargets({required String text, required String thinking}) {
    final now = DateTime.now();
    final added = _growth(_text, text) + _growth(_thinking, thinking);
    if (_lastArrival != null && added > 0) {
      final gap = now.difference(_lastArrival!).inMilliseconds;
      if (gap > 0) {
        _gapMs = _gapMs * 0.6 + gap * 0.4;
      }
    }
    if (added > 0) _lastArrival = now;
    _text = text;
    _thinking = thinking;
    final textLen = text.runes.length;
    final thinkingLen = thinking.runes.length;
    if (_textShown > textLen) _textShown = textLen;
    if (_thinkingShown > thinkingLen) _thinkingShown = thinkingLen;
    if (!isCaughtUp && (_caughtUp == null || _caughtUp!.isCompleted)) {
      _caughtUp = Completer<void>();
    }
  }

  /// Shows the next grapheme (more than one only when the buffer is far ahead
  /// of the recent arrival gap, so fast models stay in sync).
  bool advance() {
    if (isCaughtUp) return false;
    var budget = _takeCount(backlog);
    var changed = false;
    final thinkingLen = _thinking.runes.length;
    final textLen = _text.runes.length;
    while (budget > 0 && _thinkingShown < thinkingLen) {
      _thinkingShown++;
      budget--;
      changed = true;
    }
    while (budget > 0 && _textShown < textLen) {
      _textShown++;
      budget--;
      changed = true;
    }
    if (isCaughtUp) _finishCaughtUp();
    return changed;
  }

  /// Delay before the next grapheme so [backlog] drains across the latest gap.
  Duration nextDelay() {
    final pending = backlog;
    if (pending <= 0) return const Duration(milliseconds: 16);
    final ms = (_gapMs / pending).clamp(8.0, 32.0);
    return Duration(milliseconds: ms.round());
  }

  void snap() {
    _textShown = _text.runes.length;
    _thinkingShown = _thinking.runes.length;
    _finishCaughtUp();
  }

  Future<void> whenCaughtUp() {
    if (isCaughtUp) return Future<void>.value();
    _caughtUp ??= Completer<void>();
    return _caughtUp!.future;
  }

  void _finishCaughtUp() {
    final waiter = _caughtUp;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
  }

  int _takeCount(int pending) {
    if (pending > 80) return 3;
    if (pending > 24) return 2;
    return 1;
  }

  static int _growth(String previous, String next) {
    final prev = previous.runes.length;
    final nextLen = next.runes.length;
    if (nextLen <= prev) return 0;
    return nextLen - prev;
  }

  static String _slice(String value, int count) {
    if (count <= 0) return '';
    if (count >= value.runes.length) return value;
    return String.fromCharCodes(value.runes.take(count));
  }
}
