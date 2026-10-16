/// Line-oriented three-way merge for two edits of the same plain-text chapter.
class TextMergeResult {
  const TextMergeResult({required this.text, required this.hasConflict});

  final String text;
  final bool hasConflict;
}

const localConflictStart = '<<<<<<< 本机';
const conflictDivider = '=======';
const remoteConflictEnd = '>>>>>>> 云端';

/// Combines [local] and [remote] against their shared [base].
///
/// Edits to different lines are kept together. Two insertions at the same
/// point are concatenated (local, then remote). Replacements of the same
/// text stay in the result between conflict markers.
TextMergeResult mergeDivergedText({
  required String base,
  required String local,
  required String remote,
}) {
  if (local == remote) {
    return TextMergeResult(text: local, hasConflict: false);
  }
  if (local == base) return TextMergeResult(text: remote, hasConflict: false);
  if (remote == base) return TextMergeResult(text: local, hasConflict: false);
  final merged = _mergeSequences<String>(
    _lines(base),
    _lines(local),
    _lines(remote),
    joinConflict: _conflictLines,
    refine: _mergeChangedLine,
  );
  return TextMergeResult(
    text: merged.values.join('\n'),
    hasConflict: merged.conflict,
  );
}

List<String> _lines(String text) {
  if (text.isEmpty) return const [];
  return text.split('\n');
}

List<String> _conflictLines(List<String> local, List<String> remote) => [
  localConflictStart,
  ...local,
  conflictDivider,
  ...remote,
  remoteConflictEnd,
];

/// When both sides rewrote one line, merge that line by character.
List<String>? _mergeChangedLine(
  List<String> base,
  List<String> local,
  List<String> remote,
) {
  if (base.length != 1 || local.length != 1 || remote.length != 1) {
    return null;
  }
  final merged = _mergeSequences<int>(
    base.single.runes.toList(),
    local.single.runes.toList(),
    remote.single.runes.toList(),
    joinConflict: (left, right) => null,
    refine: null,
  );
  if (merged.conflict) return null;
  return [String.fromCharCodes(merged.values)];
}

class _Merged<T> {
  const _Merged(this.values, {required this.conflict});

  final List<T> values;
  final bool conflict;
}

class _Edit<T> {
  const _Edit(this.start, this.end, this.inserted);

  final int start;
  final int end;
  final List<T> inserted;
}

_Merged<T> _mergeSequences<T>(
  List<T> base,
  List<T> local,
  List<T> remote, {
  required List<T>? Function(List<T> local, List<T> remote) joinConflict,
  required List<T>? Function(List<T> base, List<T> local, List<T> remote)?
  refine,
}) {
  final left = _edits(base, local);
  final right = _edits(base, remote);
  final out = <T>[];
  var conflict = false;
  var baseIndex = 0;
  var i = 0;
  var j = 0;
  while (i < left.length || j < right.length || baseIndex < base.length) {
    final nextLeft = i < left.length ? left[i].start : base.length;
    final nextRight = j < right.length ? right[j].start : base.length;
    final next = nextLeft < nextRight ? nextLeft : nextRight;
    if (next > baseIndex) {
      final end = next > base.length ? base.length : next;
      out.addAll(base.sublist(baseIndex, end));
      baseIndex = end;
      if (baseIndex >= base.length && i >= left.length && j >= right.length) {
        break;
      }
    }
    final takeLeft = i < left.length && left[i].start == baseIndex;
    final takeRight = j < right.length && right[j].start == baseIndex;
    if (takeLeft && takeRight) {
      final end = left[i].end > right[j].end ? left[i].end : right[j].end;
      final applied = _applyOverlap(
        base: base,
        left: left,
        right: right,
        i: i,
        j: j,
        end: end,
        joinConflict: joinConflict,
        refine: refine,
      );
      out.addAll(applied.values);
      conflict = conflict || applied.conflict;
      baseIndex = applied.end;
      i = applied.i;
      j = applied.j;
      continue;
    }
    if (takeLeft && j < right.length && right[j].start < left[i].end) {
      final end = left[i].end > right[j].end ? left[i].end : right[j].end;
      final applied = _applyOverlap(
        base: base,
        left: left,
        right: right,
        i: i,
        j: j,
        end: end,
        joinConflict: joinConflict,
        refine: refine,
      );
      out.addAll(applied.values);
      conflict = conflict || applied.conflict;
      baseIndex = applied.end;
      i = applied.i;
      j = applied.j;
      continue;
    }
    if (takeRight && i < left.length && left[i].start < right[j].end) {
      final end = left[i].end > right[j].end ? left[i].end : right[j].end;
      final applied = _applyOverlap(
        base: base,
        left: left,
        right: right,
        i: i,
        j: j,
        end: end,
        joinConflict: joinConflict,
        refine: refine,
      );
      out.addAll(applied.values);
      conflict = conflict || applied.conflict;
      baseIndex = applied.end;
      i = applied.i;
      j = applied.j;
      continue;
    }
    if (takeLeft) {
      out.addAll(left[i].inserted);
      baseIndex = left[i].end;
      i++;
      continue;
    }
    if (takeRight) {
      out.addAll(right[j].inserted);
      baseIndex = right[j].end;
      j++;
      continue;
    }
    break;
  }
  return _Merged(out, conflict: conflict);
}

class _Overlap<T> {
  const _Overlap({
    required this.values,
    required this.conflict,
    required this.end,
    required this.i,
    required this.j,
  });

  final List<T> values;
  final bool conflict;
  final int end;
  final int i;
  final int j;
}

_Overlap<T> _applyOverlap<T>({
  required List<T> base,
  required List<_Edit<T>> left,
  required List<_Edit<T>> right,
  required int i,
  required int j,
  required int end,
  required List<T>? Function(List<T> local, List<T> remote) joinConflict,
  required List<T>? Function(List<T> base, List<T> local, List<T> remote)?
  refine,
}) {
  final start = left[i].start < right[j].start ? left[i].start : right[j].start;
  var regionEnd = end < start ? start : end;
  var nextI = i;
  var nextJ = j;
  if (regionEnd == start) {
    if (nextI < left.length &&
        left[nextI].start == start &&
        left[nextI].end == start) {
      nextI++;
    }
    if (nextJ < right.length &&
        right[nextJ].start == start &&
        right[nextJ].end == start) {
      nextJ++;
    }
  } else {
    while (nextI < left.length && left[nextI].start < regionEnd) {
      if (left[nextI].end > regionEnd) regionEnd = left[nextI].end;
      nextI++;
    }
    while (nextJ < right.length && right[nextJ].start < regionEnd) {
      if (right[nextJ].end > regionEnd) regionEnd = right[nextJ].end;
      nextJ++;
    }
  }
  final local = _materialize(base, left.sublist(i, nextI), start, regionEnd);
  final remote = _materialize(base, right.sublist(j, nextJ), start, regionEnd);
  final baseSlice = base.sublist(start, regionEnd);
  final refined = refine?.call(baseSlice, local, remote);
  if (refined != null) {
    return _Overlap(
      values: refined,
      conflict: false,
      end: regionEnd,
      i: nextI,
      j: nextJ,
    );
  }
  if (_sameList(local, remote)) {
    return _Overlap(
      values: local,
      conflict: false,
      end: regionEnd,
      i: nextI,
      j: nextJ,
    );
  }
  if (_pureInsertion(left.sublist(i, nextI), start, regionEnd) &&
      _pureInsertion(right.sublist(j, nextJ), start, regionEnd)) {
    return _Overlap(
      values: [...local, ...remote],
      conflict: false,
      end: regionEnd,
      i: nextI,
      j: nextJ,
    );
  }
  final marked = joinConflict(local, remote);
  if (marked == null) {
    return _Overlap(
      values: local,
      conflict: true,
      end: regionEnd,
      i: nextI,
      j: nextJ,
    );
  }
  return _Overlap(
    values: marked,
    conflict: true,
    end: regionEnd,
    i: nextI,
    j: nextJ,
  );
}

bool _pureInsertion<T>(List<_Edit<T>> edits, int start, int end) {
  if (edits.isEmpty) return start == end;
  var covered = start;
  for (final edit in edits) {
    if (edit.start != covered || edit.end != edit.start) return false;
    covered = edit.end;
  }
  return covered == end && start == end;
}

List<T> _materialize<T>(
  List<T> base,
  List<_Edit<T>> edits,
  int start,
  int end,
) {
  final out = <T>[];
  var index = start;
  for (final edit in edits) {
    final insertion = edit.start == edit.end;
    final inRegion = insertion
        ? edit.start == start && start == end ||
              (edit.start >= start && edit.start < end)
        : edit.start < end && edit.end > start;
    if (!inRegion) continue;
    if (edit.start > index) out.addAll(base.sublist(index, edit.start));
    out.addAll(edit.inserted);
    index = edit.end;
  }
  if (index < end) out.addAll(base.sublist(index, end));
  return out;
}

List<_Edit<T>> _edits<T>(List<T> from, List<T> to) {
  if (from.length * to.length > 4000000) {
    if (_sameList(from, to)) return const [];
    return [_Edit(0, from.length, to)];
  }
  final n = from.length;
  final m = to.length;
  final lengths = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      if (from[i] == to[j]) {
        lengths[i][j] = lengths[i + 1][j + 1] + 1;
      } else {
        final down = lengths[i + 1][j];
        final right = lengths[i][j + 1];
        lengths[i][j] = down > right ? down : right;
      }
    }
  }
  final edits = <_Edit<T>>[];
  var i = 0;
  var j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && from[i] == to[j]) {
      i++;
      j++;
      continue;
    }
    final start = i;
    final inserted = <T>[];
    while (i < n || j < m) {
      if (i < n && j < m && from[i] == to[j]) break;
      if (j < m && (i == n || lengths[i][j + 1] >= lengths[i + 1][j])) {
        inserted.add(to[j]);
        j++;
      } else {
        i++;
      }
    }
    edits.add(_Edit(start, i, inserted));
  }
  return edits;
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
