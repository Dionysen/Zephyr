/// Per-book chapter list ordering in the sidebar.
///
/// [manual] follows PureWriter `rank` / `orderKey`. Rule modes only affect
/// display order; they never rewrite those fields.
enum ChapterSortMode {
  manual,
  createdAsc,
  createdDesc,
  updatedAsc,
  updatedDesc,
  titleAsc,
  titleDesc;

  bool get isManual => this == manual;

  String get storageId => name;

  static ChapterSortMode fromStorageId(String? raw) {
    if (raw == null || raw.isEmpty) return ChapterSortMode.manual;
    for (final mode in ChapterSortMode.values) {
      if (mode.storageId == raw) return mode;
    }
    return ChapterSortMode.manual;
  }
}
