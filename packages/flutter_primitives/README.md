# flutter_primitives

Reusable Flutter UI mechanisms without Zephyr business dependencies. Import `package:flutter_primitives/flutter_primitives.dart` or a focused library.

Available components: `AdaptiveBreakpoints`, `ColumnResizeHandle`, `NestedBackNavigator`, `SwipeDrawer`, `DualEditorPager`, and `FloatingOverlayScope`. Shared chrome styling is available through `ChromeControls`, `FloatingChrome`, `ScrollbarStyle`, and `IconToolbar`. The host provides its own theme, pane content, and data. Drawer gesture blocking uses `DrawerDragBlockNotification` and `DrawerOpenSwipeBlockNotification`.

`AdaptiveSettingsPage` takes `SettingsGroup` lists containing `SettingsToggleItem`, `SettingsChoiceItem`, `SettingsNumberItem`, or `SettingsActionItem`. It chooses compact cards and pickers or wide inline controls from available width. `AdaptiveSettingsView` embeds the same content without its own scaffold. The host only provides values, callbacks, and its Material theme; no platform check is needed.

Wrap the app once in `DesignStyleScope(style: DesignStyle.material | DesignStyle.cupertino | DesignStyle.custom, child: app)`. The settings API renders Material or Cupertino controls independently of platform and width. `custom` uses the host's themed Material controls; a product can subclass `SettingsItem` for additional controls.

For controls outside settings, use `DesignSwitch` and `DesignSlider` so a product style change selects the matching control without rewriting feature code.
