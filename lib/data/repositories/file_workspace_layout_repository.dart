import '../../domain/models/workspace_layout.dart';
import '../../domain/repositories/workspace_layout_repository.dart';
import '../services/workspace_layout_file_storage.dart';

class FileWorkspaceLayoutRepository implements WorkspaceLayoutRepository {
  FileWorkspaceLayoutRepository(this._storage);

  final WorkspaceLayoutFileStorage _storage;

  @override
  Future<WorkspaceLayout> load() async {
    final values = await _storage.read();
    if (values == null) {
      return WorkspaceLayout.defaults;
    }
    final width = values['sidebarWidth'];
    if (width is! num) {
      throw const FormatException('Invalid sidebarWidth preference.');
    }
    return WorkspaceLayout.clamped(width.toDouble());
  }

  @override
  Future<void> save(WorkspaceLayout layout) =>
      _storage.write({'sidebarWidth': layout.sidebarWidth});
}
