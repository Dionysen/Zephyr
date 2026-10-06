import 'package:flutter/services.dart';

class PickedLibraryFolder {
  const PickedLibraryFolder({required this.path, this.bookmark});

  final String path;
  final String? bookmark;
}

/// macOS security-scoped bookmarks so a user-selected writing folder can be
/// reopened after the process exits.
class FolderBookmarkAccess {
  FolderBookmarkAccess({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('zephyr/folder_bookmark');

  final MethodChannel _channel;

  Future<PickedLibraryFolder?> pickDirectory() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'pickDirectory',
    );
    final path = result?['path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }
    final bookmark = result?['bookmark'] as String?;
    return PickedLibraryFolder(
      path: path,
      bookmark: bookmark == null || bookmark.isEmpty ? null : bookmark,
    );
  }

  Future<String?> restore(String bookmark) =>
      _channel.invokeMethod<String>('resolve', bookmark);
}
