/// Default sidebar volume expansion for [WritingLibraryRepository] test fakes.
mixin SidebarVolumeExpansionRepositoryMethods {
  Future<Map<String, Set<String>>> loadSidebarVolumeExpansionByBook() async =>
      {};

  Future<void> saveSidebarVolumeExpansionByBook(
    Map<String, Set<String>> byBook,
  ) async {}
}
