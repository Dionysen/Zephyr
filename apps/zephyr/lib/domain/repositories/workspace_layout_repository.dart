import '../models/workspace_layout.dart';

abstract interface class WorkspaceLayoutRepository {
  Future<WorkspaceLayout> load();
  Future<void> save(WorkspaceLayout layout);
}
