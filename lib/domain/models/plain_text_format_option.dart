/// Individual plain-text formatting actions for the quick-toolbar format panel.
enum PlainTextFormatOption {
  keepParagraphBlanks,
  removeParagraphBlanks,
  insertCjkLatinSpaces,
  addParagraphIndent,
  removeParagraphIndent,
  simplifiedToTraditional,
  traditionalToSimplified,
  halfwidthToFullwidth,
}

/// Checkbox state for batch formatting. Options in the same [exclusiveGroups]
/// entry cannot be selected together.
class PlainTextFormatSelection {
  const PlainTextFormatSelection([this._selected = const {}]);

  static const exclusiveGroups = <Set<PlainTextFormatOption>>[
    {
      PlainTextFormatOption.keepParagraphBlanks,
      PlainTextFormatOption.removeParagraphBlanks,
    },
    {
      PlainTextFormatOption.addParagraphIndent,
      PlainTextFormatOption.removeParagraphIndent,
    },
    {
      PlainTextFormatOption.simplifiedToTraditional,
      PlainTextFormatOption.traditionalToSimplified,
    },
  ];

  static const defaults = PlainTextFormatSelection({
    PlainTextFormatOption.keepParagraphBlanks,
    PlainTextFormatOption.addParagraphIndent,
  });

  final Set<PlainTextFormatOption> _selected;

  Set<PlainTextFormatOption> get selected => Set.unmodifiable(_selected);

  bool isSelected(PlainTextFormatOption option) => _selected.contains(option);

  PlainTextFormatSelection toggle(PlainTextFormatOption option, bool on) {
    final next = Set<PlainTextFormatOption>.from(_selected);
    if (on) {
      for (final group in exclusiveGroups) {
        if (group.contains(option)) {
          next.removeAll(group.where((o) => o != option));
        }
      }
      next.add(option);
    } else {
      next.remove(option);
    }
    return PlainTextFormatSelection(next);
  }

  static PlainTextFormatSelection fromStoredIds(Iterable<String> ids) {
    final parsed = <PlainTextFormatOption>{};
    for (final id in ids) {
      for (final option in PlainTextFormatOption.values) {
        if (option.name == id) {
          parsed.add(option);
          break;
        }
      }
    }
    if (parsed.isEmpty) return defaults;
    return PlainTextFormatSelection(parsed);
  }

  List<String> toIds() =>
      _selected.map((o) => o.name).toList(growable: false);
}
