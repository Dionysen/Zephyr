import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/folder_bookmark.dart';

import '../../../core/breakpoints.dart';
import '../../../core/zephyr_scope.dart';
import '../../editor/view_models/library_view_model.dart';
import '../../settings/views/settings_page.dart';
import 'workspace_editor.dart';
import 'workspace_sidebar.dart';

/// Adaptive writing workspace. Compact and expanded layouts share the same
/// sidebar, header, and editor rather than forking platform-specific pages.
class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  LibraryViewModel? _library;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _library = ZephyrScope.of(context).library;
    if (_started) {
      return;
    }
    _started = true;
    _library!.load();
  }

  @override
  void dispose() {
    _library?.save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ZephyrScope.of(context);
    return ListenableBuilder(
      listenable: scope.library,
      builder: (context, _) {
        final model = scope.library;
        if (model.error != null) {
          return _LibraryErrorPage(error: model.error!);
        }
        if (model.library == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = ZephyrBreakpoints.isCompact(constraints.maxWidth);
            return Scaffold(
              drawer: compact
                  ? Drawer(
                      width: model.sidebarWidth,
                      child: SafeArea(
                        child: WorkspaceSidebar(
                          model: model,
                          mode: SidebarMode.drawer,
                          openLibrary: _openLibrary,
                          openSettings: _openSettings,
                        ),
                      ),
                    )
                  : null,
              body: SafeArea(
                child: compact
                    ? Column(
                        children: [
                          WorkspaceHeader(model: model, showMenuButton: true),
                          Expanded(
                            child: WorkspaceEditor(
                              model: model,
                              preferences: scope.editorPreferences,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedContainer(
                            duration: model.isResizingSidebar
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            width: model.isSidebarExpanded
                                ? model.sidebarWidth
                                : 0,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                minWidth: model.sidebarWidth,
                                maxWidth: model.sidebarWidth,
                                child: WorkspaceSidebar(
                                  model: model,
                                  mode: SidebarMode.docked,
                                  openLibrary: _openLibrary,
                                  openSettings: _openSettings,
                                ),
                              ),
                            ),
                          ),
                          if (model.isSidebarExpanded)
                            SidebarResizeHandle(
                              model: model,
                              maxWidth: _maxSidebarWidth(constraints.maxWidth),
                            ),
                          Expanded(
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    WorkspaceHeader(
                                      model: model,
                                      showSidebarToggle:
                                          !model.isSidebarExpanded,
                                    ),
                                    Expanded(
                                      child: WorkspaceEditor(
                                        model: model,
                                        preferences: scope.editorPreferences,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLibrary() async {
    final picked = await _pickLibraryFolder();
    if (picked != null && mounted) {
      await ZephyrScope.of(context).library
          .openLibrary(picked.path, bookmark: picked.bookmark);
    }
  }

  Future<PickedLibraryFolder?> _pickLibraryFolder() async {
    if (Platform.isMacOS) {
      try {
        return await FolderBookmarkAccess().pickDirectory();
      } on Object {
        // Native folder chrome is optional in tests and unsupported embeds.
      }
    }
    final root = await FilePicker.getDirectoryPath();
    if (root == null) {
      return null;
    }
    return PickedLibraryFolder(path: root);
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  double _maxSidebarWidth(double workspaceWidth) {
    final available = workspaceWidth - 360 - SidebarResizeHandle.width;
    return available.clamp(
      LibraryViewModel.minSidebarWidth,
      LibraryViewModel.maxSidebarWidth,
    );
  }
}

class _LibraryErrorPage extends StatelessWidget {
  const _LibraryErrorPage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not open library: $error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
