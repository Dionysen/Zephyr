import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/domain/models/app_theme_mode.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/library_backup.dart';
import 'package:zephyr/domain/models/purewriter_models.dart';
import 'package:zephyr/domain/models/settings_navigation.dart';
import 'package:zephyr/domain/models/theme_color_pack.dart';
import 'package:zephyr/domain/models/theme_tokens.dart';
import 'package:zephyr/domain/models/ui_preferences.dart';
import 'package:zephyr/domain/models/quick_toolbar_config.dart';
import 'package:zephyr/domain/models/keyboard_shortcuts.dart';
import 'package:zephyr/domain/repositories/backup_preferences_repository.dart';
import 'package:zephyr/domain/repositories/editor_preferences_repository.dart';
import 'package:zephyr/domain/repositories/keyboard_shortcuts_repository.dart';
import 'package:zephyr/domain/repositories/quick_toolbar_preferences_repository.dart';
import 'package:zephyr/domain/repositories/settings_navigation_repository.dart';
import 'package:zephyr/domain/repositories/theme_preferences_repository.dart';
import 'package:zephyr/domain/repositories/writing_library_repository.dart';
import 'package:zephyr/ui/core/zephyr_scope.dart';
import 'package:zephyr/ui/core/zephyr_theme.dart';
import 'package:zephyr/ui/features/editor/view_models/editor_preferences_view_model.dart';
import 'package:zephyr/ui/features/editor/view_models/library_view_model.dart';
import 'package:zephyr/ui/features/editor/view_models/quick_toolbar_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/backup_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/cloud_sync_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/font_library.dart';
import 'package:zephyr/ui/features/settings/view_models/keyboard_shortcuts_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/settings_view_model.dart';
import 'package:zephyr/ui/features/settings/view_models/theme_view_model.dart';
import 'package:zephyr/l10n/app_localizations.dart';
import 'package:zephyr/ui/features/settings/views/settings_page.dart';
import 'package:zephyr/ui/features/workspace/views/workspace_page.dart';
import 'package:zephyr/ui/features/workspace/views/library_switcher_menu.dart';
import 'package:zephyr/ui/features/workspace/views/workspace_settings_panel.dart';
import 'package:zephyr/ui/features/workspace/views/workspace_sidebar.dart';

void main() {
  testWidgets('opening a library does not pull a cloud snapshot', (
    tester,
  ) async {
    final library = LibraryViewModel(_LibraryRepository());
    final cloud = _ExitCloudSyncViewModel(library);
    addTearDown(() {
      cloud.dispose();
      library.dispose();
    });

    await tester.pumpWidget(_app(library: library, cloudSync: cloud));
    await tester.pumpAndSettle();

    expect(cloud.syncCalls, 0);
  });

  testWidgets('root exit stays open when flush fails', (tester) async {
    final library = _FlushFailLibrary(_LibraryRepository());
    final cloud = _ExitCloudSyncViewModel(library);
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      cloud.dispose();
      // Skip library.dispose — flushPending is stubbed to throw.
    });

    await tester.pumpWidget(_app(library: library, cloudSync: cloud));
    await tester.pumpAndSettle();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(exits, 0);
    expect(cloud.backupCalls, 0);
    expect(find.byType(WorkspacePage), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('root exit leaves without waiting for in-process cloud upload', (
    tester,
  ) async {
    final library = LibraryViewModel(_LibraryRepository());
    final cloud = _ExitCloudSyncViewModel(library);
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      cloud.dispose();
      library.dispose();
    });

    await tester.pumpWidget(_app(library: library, cloudSync: cloud));
    await tester.pumpAndSettle();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(exits, 1);
    expect(cloud.backupCalls, 0);
  });

  testWidgets('root exit skips in-process cloud upload when signed out', (
    tester,
  ) async {
    final library = LibraryViewModel(_LibraryRepository());
    final cloud = _ExitCloudSyncViewModel(library, signedIn: false);
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      cloud.dispose();
      library.dispose();
    });

    await tester.pumpWidget(_app(library: library, cloudSync: cloud));
    await tester.pumpAndSettle();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(exits, 1);
    expect(cloud.backupCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('volume header stays pinned only while its chapters scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(
      _LibraryRepository(scrollingSections: true),
    );
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();

    final scroll = find.descendant(
      of: find.byType(WorkspaceSidebar),
      matching: find.byType(CustomScrollView),
    );
    final initialHeaderTop = tester.getTopLeft(find.text('Volume A')).dy;
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        )
        .position;

    position.jumpTo(220);
    await tester.pumpAndSettle();
    expect(find.text('Volume A').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Volume A')).dy,
      closeTo(initialHeaderTop, 3),
    );

    position.jumpTo(position.maxScrollExtent * .75);
    await tester.pumpAndSettle();
    expect(find.text('Volume A').hitTestable(), findsNothing);
    expect(find.text('Volume B').hitTestable(), findsOneWidget);
    // Later pinned headers can sit one volume-gap below the first header top.
    expect(
      tester.getTopLeft(find.text('Volume B')).dy,
      closeTo(initialHeaderTop, 8),
    );
    await tester.tap(find.text('Volume B'));
    await tester.pumpAndSettle();
    expect(library.isVolumeExpanded('volume-b'), isFalse);
  });

  testWidgets(
    'collapsing the scrolled volume keeps the next volume at its start',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = LibraryViewModel(
        _LibraryRepository(scrollingSections: true),
      );
      await tester.pumpWidget(_app(library: library));
      await tester.pumpAndSettle();

      final scroll = find.descendant(
        of: find.byType(WorkspaceSidebar),
        matching: find.byType(CustomScrollView),
      );
      final initialHeaderTop = tester.getTopLeft(find.text('Volume A')).dy;
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;

      position.jumpTo(220);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Volume A')).dy,
        closeTo(initialHeaderTop, 3),
      );

      await tester.tap(find.text('Volume A'));
      await tester.pumpAndSettle();
      expect(library.isVolumeExpanded('volume-a'), isFalse);
      expect(find.text('Volume A').hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Volume A')).dy,
        closeTo(initialHeaderTop, 3),
      );
      expect(find.text('Volume B').hitTestable(), findsOneWidget);
      expect(find.text('B chapter 0').hitTestable(), findsOneWidget);
      expect(find.text('B chapter 10').hitTestable(), findsNothing);
    },
  );

  testWidgets('trash appears in the book picker and shows discarded chapters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(_LibraryRepository());
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();
    expect(library.selectedBook?.id, 'Default');

    await tester.tap(find.text('Book A'));
    await tester.pumpAndSettle();
    final trashLabel = tester.widget<Text>(find.text('Trash'));
    final trashContext = tester.element(find.text('Trash'));
    final trashColor = Theme.of(trashContext).colorScheme.error;
    expect(trashLabel.style?.color, trashColor);
    expect(find.byIcon(Icons.book_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));

    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(library.selectedBook?.id, WritingFolder.trashId);
    final selectedTrash = tester.widget<Text>(find.text('Trash'));
    expect(selectedTrash.style?.color, trashColor);
    expect(
      find.ancestor(
        of: find.text('Discarded chapter'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byIcon(Icons.add),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'book row selects across its full width while the overlaid edit button stays separate',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final library = LibraryViewModel(_LibraryRepository());
      await tester.pumpWidget(_app(library: library));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fiction'));
      await tester.pumpAndSettle();
      expect(library.selectedBook?.id, 'book-b');

      await tester.tap(find.text('Book B').first);
      await tester.pumpAndSettle();
      final bookRow = find
          .ancestor(
            of: find.text('Book A').last,
            matching: find.byType(InkWell),
          )
          .first;
      final rowRect = tester.getRect(bookRow);
      final editRect = tester.getRect(find.byIcon(Icons.edit_outlined).first);
      expect(rowRect.contains(editRect.center), isTrue);
      await tester.tapAt(Offset(rowRect.right - 2, rowRect.bottom - 2));
      await tester.pumpAndSettle();
      expect(library.selectedBook?.id, 'Default');

      await tester.tap(find.text('Book A').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined).last);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(library.selectedBook?.id, 'Default');
    },
  );

  testWidgets('wide layout docks the shared sidebar', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final sidebar = tester.getRect(find.byType(WorkspaceSidebar));
    final addButton = tester.getRect(find.byTooltip('Add'));
    final searchButton = tester.getRect(find.byTooltip('Search'));
    final expandButton = tester.getRect(find.byTooltip('Collapse all'));
    final locateButton = tester.getRect(
      find.byTooltip('Locate current chapter'),
    );
    final sortButton = tester.getRect(find.byTooltip('Sort order'));
    expect(addButton.left, lessThan(searchButton.left));
    expect(searchButton.left, lessThan(expandButton.left));
    expect(expandButton.left, lessThan(locateButton.left));
    expect(locateButton.left, lessThan(sortButton.left));
    expect(sortButton.right, closeTo(sidebar.right, 8));
    expect(find.byIcon(Icons.drag_indicator), findsNothing);

    await tester.tap(find.byTooltip('Sort order'));
    await tester.pumpAndSettle();
    expect(find.text('Manual order'), findsOneWidget);
    final manualItem = tester.widget<MenuItemButton>(
      find.ancestor(
        of: find.text('Manual order'),
        matching: find.byType(MenuItemButton),
      ),
    );
    expect(
      manualItem.style?.overlayColor?.resolve({WidgetState.pressed}),
      isNot(Colors.transparent),
    );
    await tester.tap(find.text('Adjust order'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Done adjusting order'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsWidgets);

    await tester.tap(find.byTooltip('Collapse all'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expand all'), findsOneWidget);
    expect(find.text('Volume A'), findsOneWidget);
  });

  testWidgets(
    'chapter content has equal insets and preview removes line breaks and indent characters',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final chapterInkWell = find
          .ancestor(of: find.text('Chapter A'), matching: find.byType(InkWell))
          .first;
      final padding = tester.widget<InkWell>(chapterInkWell).child! as Padding;
      final insets = padding.padding.resolve(TextDirection.ltr);
      expect(insets.left, insets.right);
      final preview = tester.widget<Text>(
        find.text('First line Second line Third line'),
      );
      final metadata = tester.widget<Text>(
        find.text('Created 2025-12-19 · Edited 2026-01-02 · 42 words'),
      );
      expect(preview.style?.fontSize, metadata.style?.fontSize);
      expect(
        find.text(
          'First line\n\u3000\u3000Second line\r\n\u3000\u3000Third line',
        ),
        findsNothing,
      );
    },
  );

  testWidgets('compact layout keeps two editors behind mirrored book drawers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open library'), findsNWidgets(2));
    expect(find.byTooltip('Hide sidebar'), findsNothing);
    expect(find.byTooltip('Collapse all').hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Open library').first);
    await tester.pumpAndSettle();
    expect(find.text('Book A'), findsWidgets);
    expect(find.byTooltip('Collapse all').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Add').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Search').hitTestable(), findsOneWidget);
  });

  testWidgets('volume context menu opens delete dialog with two choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volume A'), buttons: 2);
    await tester.pumpAndSettle();
    expect(find.text('Insert volume below'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsWidgets);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete volume'), findsOneWidget);
    expect(find.text('Delete volume only'), findsOneWidget);
    expect(find.text('Delete volume and chapters'), findsOneWidget);
  });

  testWidgets('chapter context menu confirms trash before deleting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(WorkspaceSidebar),
        matching: find.text('Chapter A'),
      ),
      buttons: 2,
    );
    await tester.pumpAndSettle();
    expect(find.text('Insert chapter below'), findsOneWidget);
    expect(find.text('Move to volume'), findsOneWidget);

    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete chapter'), findsOneWidget);
    expect(find.textContaining('to the trash'), findsOneWidget);
  });

  testWidgets('sidebar add menu creates a volume in the book', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(_LibraryRepository());
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);

    await tester.tap(find.byTooltip(l10n.tooltipAdd));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tooltipNewVolume));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(WorkspaceSidebar),
        matching: find.text('Untitled'),
      ),
      findsOneWidget,
    );
    expect(
      library.library?.categories.any(
        (volume) => volume.folderId == 'Default' && volume.name == 'Untitled',
      ),
      isTrue,
    );
  });

  testWidgets('volume menu creates and reveals a chapter at its end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final library = LibraryViewModel(
      _LibraryRepository(scrollingSections: true),
    );
    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volume A'), buttons: 2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insert chapter at end of volume'));
    await tester.pumpAndSettle();

    final created = find.descendant(
      of: find.byType(WorkspaceSidebar),
      matching: find.text('Untitled'),
    );
    expect(created, findsOneWidget);
    expect(library.article?.categoryId, 'volume-a');
  });

  testWidgets('expanded settings open above the sidebar library dock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);

    await tester.tap(find.byTooltip(l10n.tooltipSettings).first);
    await tester.pumpAndSettle();

    expect(find.byType(WorkspaceSettingsPanel).hitTestable(), findsOneWidget);
    expect(find.text(l10n.settingsTitle), findsWidgets);
    expect(find.text(l10n.settingsSectionGeneral), findsWidgets);
    expect(find.text(l10n.languageTitle), findsOneWidget);
    expect(find.text(l10n.hideQuickToolbarTitle), findsOneWidget);
    expect(find.text(l10n.showChapterDetailsTitle), findsOneWidget);
    expect(find.text(l10n.backupAutoTitle), findsNothing);
    expect(find.text(l10n.settingsSectionCloud), findsOneWidget);
    expect(find.text(l10n.settingsSectionEditor), findsOneWidget);
    expect(find.text(l10n.immersiveStatusBarTitle), findsNothing);
    expect(find.text(l10n.hideStatusBarIconsTitle), findsNothing);
    // Dock settings control stays available to toggle the panel.
    expect(find.byTooltip(l10n.tooltipSettings), findsOneWidget);

    final sidebarBox = tester.getRect(find.byType(WorkspaceSidebar));
    final panelBox = tester.getRect(find.byType(WorkspaceSettingsPanel));
    // Left-aligned with the library dock inset.
    expect(panelBox.left, closeTo(sidebarBox.left + 10, 0.5));
    // At least the pre-dock preferred width; may extend past the sidebar.
    expect(
      panelBox.width,
      greaterThanOrEqualTo(WorkspaceSettingsPanel.preferredWidth - 0.5),
    );
    expect(
      panelBox.width,
      closeTo(
        math.max(WorkspaceSettingsPanel.preferredWidth, sidebarBox.width - 20),
        0.5,
      ),
    );
    // Panel uses 2/3 of the chapter-tree stack (sidebar minus top chrome).
    expect(panelBox.height / sidebarBox.height, greaterThan(0.45));
    expect(panelBox.height / sidebarBox.height, lessThan(0.72));
    expect(panelBox.bottom, lessThan(sidebarBox.bottom - 52));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.settingsSectionCloud),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.languageTitle), findsNothing);
    expect(find.text(l10n.backupAutoTitle), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(l10n.settingsSectionEditor),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.backupAutoTitle), findsNothing);
    await tester.scrollUntilVisible(
      find.text(l10n.shortcutsManageTitle),
      300,
      scrollable: find
          .descendant(
            of: find.byType(WorkspaceSettingsPanel),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text(l10n.shortcutsManageTitle), findsOneWidget);
  });

  testWidgets('expanded settings panel closes and reopens in place', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);
    final closeTooltip = MaterialLocalizations.of(
      tester.element(find.byType(WorkspacePage)),
    ).closeButtonTooltip;

    await tester.tap(find.byTooltip(l10n.tooltipSettings));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceSettingsPanel).hitTestable(), findsOneWidget);
    expect(find.text(l10n.languageTitle).hitTestable(), findsOneWidget);

    await tester.tap(find.byTooltip(closeTooltip));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceSettingsPanel).hitTestable(), findsNothing);
    expect(find.text(l10n.languageTitle).hitTestable(), findsNothing);

    await tester.tap(find.byTooltip(l10n.tooltipSettings));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceSettingsPanel).hitTestable(), findsOneWidget);
    expect(find.text(l10n.languageTitle).hitTestable(), findsOneWidget);
    expect(find.text(l10n.settingsSectionEditor), findsWidgets);
  });

  testWidgets('compact settings still open as a full-page route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = _l10n(tester);

    await tester.tap(find.byTooltip(l10n.tooltipOpenLibrary).hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.tooltipSettings).first);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(WorkspaceSettingsPanel), findsNothing);
    expect(find.text(l10n.languageTitle), findsOneWidget);
    expect(find.text(l10n.hideQuickToolbarTitle), findsOneWidget);
    expect(find.text(l10n.showChapterDetailsTitle), findsOneWidget);
    expect(find.text(l10n.immersiveStatusBarTitle), findsOneWidget);
    expect(find.text(l10n.hideStatusBarIconsTitle), findsOneWidget);
  });

  testWidgets('guides the user to choose a PureWriter library folder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(needsLibrarySetup: true));
    await tester.pumpAndSettle();

    expect(find.text('Using a temporary library'), findsOneWidget);
    expect(find.text('Choose library'), findsOneWidget);
    expect(find.text('Temporary library'), findsWidgets);
  });

  testWidgets('library menu offers only directory reselection', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final library = LibraryViewModel(_LibraryRepository());
    await library.openLibrary('/writing/my-library');

    await tester.pumpWidget(_app(library: library));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LibrarySwitcherButton));
    await tester.pumpAndSettle();

    expect(find.text('/writing/my-library'), findsOneWidget);
    expect(find.text('Choose another directory'), findsOneWidget);
    expect(find.text('Add library'), findsNothing);
    expect(find.text('Rename library'), findsNothing);
    expect(find.text('Remove from list'), findsNothing);
  });

  testWidgets('wide layout title bar opens overflow tools', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final headerMore = find.descendant(
      of: find.byType(WorkspaceHeader),
      matching: find.byTooltip('More'),
    );
    expect(headerMore, findsOneWidget);

    await tester.tap(headerMore);
    await tester.pumpAndSettle();
    // Tests force WindowChrome.isDesktop=false, so More opens the mobile drawer.
    expect(find.textContaining('Long-press'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('compact top bar opens book and tools sheets', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final bookBar = find.byType(WorkspaceMobileBookBar).hitTestable();
    expect(find.byTooltip('More').hitTestable(), findsOneWidget);
    expect(
      find.descendant(of: bookBar, matching: find.text('Book A')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('More').hitTestable());
    await tester.pumpAndSettle();
    expect(find.textContaining('Long-press'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
    await tester.tapAt(const Offset(8, 80));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: bookBar, matching: find.text('Book A')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsOneWidget);

    await tester.tap(find.text('Book B').last);
    await tester.pumpAndSettle();
    expect(find.text('Books'), findsNothing);
    expect(find.text('Book B'), findsWidgets);
  });
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(WorkspacePage)));

Widget _app({
  LibraryViewModel? library,
  bool needsLibrarySetup = false,
  CloudSyncViewModel? cloudSync,
}) {
  library ??= LibraryViewModel(
    _LibraryRepository(),
    needsLibrarySetup: needsLibrarySetup,
  );
  final fonts = FontLibrary(_FontRepository());
  final theme = ThemeViewModel(_ThemeRepository(), fontLibrary: fonts);
  final editorPreferences = EditorPreferencesViewModel(
    _PreferencesRepository(),
    fonts,
  );
  final quickToolbar = QuickToolbarViewModel(_QuickToolbarRepository());
  final keyboardShortcuts = KeyboardShortcutsViewModel(
    _KeyboardShortcutsRepository(),
  );
  final settings = SettingsViewModel(_SettingsRepository());
  final backup = BackupViewModel(
    library: library,
    preferencesRepository: _BackupPreferencesRepository(),
  );
  cloudSync ??= CloudSyncViewModel(library: library);
  return ZephyrScope(
    library: library,
    theme: theme,
    editorPreferences: editorPreferences,
    quickToolbar: quickToolbar,
    keyboardShortcuts: keyboardShortcuts,
    settings: settings,
    backup: backup,
    cloudSync: cloudSync,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: zephyrTheme(theme.tokens),
      home: const WorkspacePage(),
    ),
  );
}

class _LibraryRepository implements WritingLibraryRepository {
  _LibraryRepository({this.scrollingSections = false});

  final bool scrollingSections;
  final extraCategories = <WritingCategory>[];
  final extraArticles = <ArticleSummary>[];

  @override
  Future<WritingLibrary> loadLibrary() async => WritingLibrary(
    folders: const [
      WritingFolder(id: 'Default', name: 'Book A', rank: 0),
      WritingFolder(id: 'book-b', name: 'Book B', rank: 1, tags: 'Fiction'),
      WritingFolder(id: WritingFolder.trashId, name: 'Trash', rank: 2),
    ],
    categories: [
      const WritingCategory(
        id: 'volume-a',
        folderId: 'Default',
        name: 'Volume A',
        rank: 0,
        collapsed: false,
      ),
      if (scrollingSections)
        const WritingCategory(
          id: 'volume-b',
          folderId: 'Default',
          name: 'Volume B',
          rank: 1,
          collapsed: false,
        ),
      ...extraCategories,
    ],
    articles: [
      ArticleSummary(
        id: 'article',
        title: 'Chapter A',
        summary:
            'First line\n\u3000\u3000Second line\r\n\u3000\u3000Third line',
        folderId: 'Default',
        categoryId: 'volume-a',
        createdAt: DateTime.utc(2025, 12, 19),
        updatedAt: DateTime.utc(2026, 1, 2),
        wordCount: 42,
      ),
      ArticleSummary(
        id: 'trashed',
        title: 'Discarded chapter',
        summary: 'Discarded content',
        folderId: WritingFolder.trashId,
        categoryId: 'volume-a',
        createdAt: DateTime.utc(2025, 12, 19),
        updatedAt: DateTime.utc(2026, 1, 2),
        wordCount: 17,
      ),
      if (scrollingSections)
        for (var index = 0; index < 14; index++)
          ArticleSummary(
            id: 'a-$index',
            title: 'A chapter $index',
            summary: 'Preview',
            folderId: 'Default',
            categoryId: 'volume-a',
            createdAt: DateTime.utc(2025, 12, 19),
            updatedAt: DateTime.utc(2026, 1, 2),
            wordCount: 7,
          ),
      ...extraArticles,
      if (scrollingSections)
        for (var index = 0; index < 14; index++)
          ArticleSummary(
            id: 'b-$index',
            title: 'B chapter $index',
            summary: 'Preview',
            folderId: 'Default',
            categoryId: 'volume-b',
            createdAt: DateTime.utc(2025, 12, 19),
            updatedAt: DateTime.utc(2026, 1, 2),
            wordCount: 7,
          ),
    ],
  );

  @override
  Future<WritingArticle> getArticle(String id) async {
    final summary = (await loadLibrary()).articles.singleWhere(
      (article) => article.id == id,
    );
    return WritingArticle(
      id: summary.id,
      title: summary.title,
      content: id == 'trashed' ? 'Discarded content' : 'Hello',
      summary: summary.summary,
      folderId: summary.folderId,
      categoryId: summary.categoryId,
      createdAt: summary.createdAt,
      updatedAt: summary.updatedAt,
      wordCount: summary.wordCount,
    );
  }

  @override
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  }) async {
    final library = await loadLibrary();
    final articles = <WritingArticle>[];
    for (final summary in library.articles) {
      final match = articleId != null
          ? summary.id == articleId
          : folderId != null && categoryId != null
          ? summary.folderId == folderId && summary.categoryId == categoryId
          : folderId != null && unfiledOnly
          ? summary.folderId == folderId && summary.categoryId == null
          : folderId != null
          ? summary.folderId == folderId
          : includeTrash || summary.folderId != WritingFolder.trashId;
      if (!match) continue;
      articles.add(await getArticle(summary.id));
    }
    return articles;
  }

  @override
  Future<WritingArticle> createArticle({
    required String folderId,
    String? categoryId,
    String? afterArticleId,
  }) async {
    final id = 'new-${extraArticles.length}';
    extraArticles.add(
      ArticleSummary(
        id: id,
        title: 'Untitled',
        summary: '',
        folderId: folderId,
        categoryId: categoryId,
        createdAt: DateTime.utc(2026, 1, 3),
        updatedAt: DateTime.utc(2026, 1, 3),
        wordCount: 0,
      ),
    );
    return getArticle(id);
  }

  @override
  Future<void> saveArticle(WritingArticle article) async {}

  @override
  Future<void> renameArticle({
    required String articleId,
    required String title,
  }) async {}

  @override
  Future<void> renameCategory({
    required String categoryId,
    required String name,
  }) async {}

  @override
  Future<void> deleteCategory({
    required String categoryId,
    required bool deleteArticles,
  }) async {
    extraCategories.removeWhere((item) => item.id == categoryId);
  }

  @override
  Future<void> moveArticleToCategory({
    required String articleId,
    String? categoryId,
  }) async {}

  @override
  Future<void> moveArticleToFolder({
    required String articleId,
    required String folderId,
  }) async {}

  @override
  Future<void> moveCategoryToFolder({
    required String categoryId,
    required String folderId,
  }) async {}

  @override
  Future<WritingFolder> convertCategoryToFolder({
    required String categoryId,
  }) async => const WritingFolder(
    id: 'converted',
    name: 'Converted',
    rank: 0,
    description: '',
    tags: '',
  );

  @override
  Future<void> reorderCategories({
    required String folderId,
    required List<String> orderedIds,
  }) async {}

  @override
  Future<void> reorderArticles({
    required String folderId,
    String? categoryId,
    required List<String> orderedIds,
  }) async {}

  LibraryLocation? _location = const LibraryLocation(
    rootPath: '/writing/book',
    schema: SchemaStatus(
      userVersion: 27,
      identityHash: 'test',
      writesAllowed: true,
    ),
  );

  @override
  LibraryLocation? get location => _location;

  @override
  Future<LibraryLocation> openLibrary(String rootPath) async {
    _location = LibraryLocation(
      rootPath: rootPath,
      schema: const SchemaStatus(
        userVersion: 27,
        identityHash: 'test',
        writesAllowed: true,
      ),
    );
    return _location!;
  }

  @override
  Future<LibraryLocation> openDefaultLibrary() =>
      openLibrary('/tmp/zephyr-temporary-library');

  @override
  Future<void> closeLibrary() async {}

  @override
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
    String? afterCategoryId,
  }) async {
    final volume = WritingCategory(
      id: 'volume-new-${extraCategories.length}',
      folderId: folderId,
      name: name,
      rank: extraCategories.length,
      collapsed: false,
    );
    if (afterCategoryId == null) {
      extraCategories.add(volume);
    } else {
      extraCategories.insert(0, volume);
    }
    return volume;
  }

  @override
  Future<void> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  }) async {}

  @override
  Future<WritingFolder> createFolder({
    required String name,
    String description = '',
    String tags = '',
  }) async => WritingFolder(
    id: 'new-book',
    name: name,
    rank: 99,
    description: description,
    tags: tags,
  );

  @override
  Future<void> deleteFolder(String folderId) async {}

  @override
  Future<void> reorderFolders({required List<String> orderedIds}) async {}

  @override
  Future<void> trashArticle(String articleId) async {}

  @override
  Future<void> restoreArticle(
    String articleId, {
    required String folderId,
  }) async {}

  @override
  Future<List<ArticleHistory>> listHistory(String articleId) async => const [];

  @override
  Future<void> restoreHistory({
    required String articleId,
    required DateTime createdAt,
  }) async {}

  @override
  Future<List<DailyWriting>> listDaily() async => const [];

  @override
  Future<Map<String, double>> readScrolls() async => const {};

  @override
  Future<void> writeScroll(String articleId, double offset) async {}

  @override
  Future<void> upsertDraft(ArticleDraft draft) async {}

  @override
  Future<void> clearDraft(String articleId) async {}

  @override
  Future<ArticleDraft?> getDraft(String articleId) async => null;

  @override
  Future<List<ArticleDraft>> listDraftsNewerThanArticles() async => const [];

  @override
  Future<List<BackupEntry>> listBackups() async => const [];

  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async =>
      BackupEntry(
        path: '/tmp/fake.pwb',
        fileName: 'fake.pwb',
        modified: DateTime.utc(2026),
        sizeBytes: 1,
        kind: kind,
      );

  @override
  Future<LibraryMergeStats> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async => LibraryMergeStats.empty;

  @override
  Future<void> pruneBackups({int keep = 25}) async {}

  @override
  Future<String> ensureCloudLibraryId() async => 'test-cloud-library-id';

  @override
  Future<bool> hasArticleContent() async => true;

  @override
  Future<void> setCloudLibraryId(String id) async {}

  @override
  Future<QuickToolbarConfig?> readQuickToolbarConfig() async => null;

  @override
  Future<void> writeQuickToolbarConfig(QuickToolbarConfig config) async {}
}

class _ThemeRepository implements ThemePreferencesRepository {
  @override
  Future<ThemeAppearance> load() async => ThemeAppearance(
    mode: AppThemeMode.system,
    lightTokens: ThemeTokens.presets[ThemePreset.light]!,
    darkTokens: ThemeTokens.defaults,
    lightPackId: ThemeColorPack.builtInId(ThemePreset.light),
    darkPackId: ThemeColorPack.builtInId(ThemePreset.darkModern),
    customPacks: const [],
    ui: UiPreferences.defaults,
  );

  @override
  Future<void> save(ThemeAppearance appearance) async {}
}

class _PreferencesRepository implements EditorPreferencesRepository {
  @override
  Future<EditorPreferences> load() async => EditorPreferences.defaults;

  @override
  Future<void> save(EditorPreferences preferences) async {}
}

class _QuickToolbarRepository implements QuickToolbarPreferencesRepository {
  @override
  Future<QuickToolbarConfig> load() async => QuickToolbarConfig.defaults;

  @override
  Future<void> save(QuickToolbarConfig config) async {}
}

class _KeyboardShortcutsRepository implements KeyboardShortcutsRepository {
  @override
  Future<ShortcutOverrides> load() async => ShortcutOverrides.empty;

  @override
  Future<void> save(ShortcutOverrides overrides) async {}
}

class _BackupPreferencesRepository implements BackupPreferencesRepository {
  BackupPreferences preferences = BackupPreferences.defaults;

  @override
  Future<BackupPreferences> load() async => preferences;

  @override
  Future<void> save(BackupPreferences preferences) async {
    this.preferences = preferences;
  }
}

class _SettingsRepository implements SettingsNavigationRepository {
  SettingsNavigation navigation = SettingsNavigation.defaults;

  @override
  Future<SettingsNavigation> load() async => navigation;

  @override
  Future<void> save(SettingsNavigation navigation) async {
    this.navigation = navigation;
  }
}

class _FontRepository implements SystemFontRepository {
  @override
  Future<List<SystemFont>> listFonts() async => const [];

  @override
  Future<String?> loadFont(SystemFont font) async => null;

  @override
  Future<SystemFont?> importFont(String sourcePath) async => null;

  @override
  Future<bool> deleteImportedFont(SystemFont font) async => false;
}

class _FlushFailLibrary extends LibraryViewModel {
  // ignore: use_super_parameters
  _FlushFailLibrary(WritingLibraryRepository repository) : super(repository);

  @override
  Future<void> flushPending() async {
    throw StateError('Flush failed');
  }
}

class _ExitCloudSyncViewModel extends CloudSyncViewModel {
  _ExitCloudSyncViewModel(LibraryViewModel library, {this.signedIn = true})
    : super(library: library);

  final bool signedIn;
  Object? failure;
  int backupCalls = 0;
  int syncCalls = 0;
  var pending = false;

  @override
  bool get cloudBackupEnabled => true;

  @override
  bool get isSignedIn => signedIn;

  @override
  bool get pendingCloudBackup => pending;

  @override
  Object? get error => failure;

  @override
  Future<void> markPendingCloudBackup() async {
    pending = true;
  }

  @override
  Future<void> catchUpPendingCloudBackup() async {}

  @override
  Future<void> backupNow() async {
    backupCalls++;
  }

  @override
  Future<CloudPullResult?> syncNow() async {
    syncCalls++;
    return CloudPullResult.skipped;
  }
}
