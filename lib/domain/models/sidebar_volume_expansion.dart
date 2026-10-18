/// Remembered sidebar volume expand/collapse for one book.
class SidebarVolumeExpansionEntry {
  const SidebarVolumeExpansionEntry({
    required this.expandedVolumeIds,
    required this.updatedAt,
  });

  /// Expanded volume ids. Empty means every volume is collapsed.
  final List<String> expandedVolumeIds;
  final int updatedAt;

  Set<String> toExpandedSet() => expandedVolumeIds.toSet();

  Map<String, Object?> toJson() => {
    'volumes': expandedVolumeIds,
    'updatedAt': updatedAt,
  };

  static SidebarVolumeExpansionEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final volumes = raw['volumes'];
    final updatedAt = raw['updatedAt'];
    if (updatedAt is! num) return null;
    return SidebarVolumeExpansionEntry(
      expandedVolumeIds: volumes is List
          ? volumes.whereType<String>().toList(growable: false)
          : const [],
      updatedAt: updatedAt.toInt(),
    );
  }

  static SidebarVolumeExpansionEntry? merge(
    SidebarVolumeExpansionEntry? local,
    SidebarVolumeExpansionEntry? remote,
  ) {
    if (local == null) return remote;
    if (remote == null) return local;
    return remote.updatedAt >= local.updatedAt ? remote : local;
  }
}
