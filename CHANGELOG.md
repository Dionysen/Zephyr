# Changelog

## Unreleased

- Replaced the desktop-only settings child window with a shared in-app settings route so appearance stays live against the writing workspace on every platform.
- Pair the editor settings scrollbar with its list scroll controller, and keep native window backdrop color in sync with the active theme.
- Load system fonts only when the editor settings page opens, and skip unused font registration until a writing session needs it.
- Fixed editor startup notifications during widget construction and made history snapshots conditional on the compatible `History` table being present.

## 0.1.0 - Unreleased

- Created the cross-platform Zephyr foundation with a PureWriter v27-compatible `App/Room.db` library, article list and autosaving editor shell.
- Reworked the desktop editor shell into an immersive sidebar workspace with animated sidebar visibility, book selection, volume and chapter navigation, and a floating library-directory switcher.
- Applied Vellum-aligned dark shell tokens for quiet editor surfaces, compact typography, subtle outlines, and layered sidebar navigation.
- Fixed a desktop shell assertion caused by assigning duplicate corner-shape configuration to navigation surfaces.
- Added persistent, user-editable writing-shell theme tokens and a settings dialog opened from the library dock.
- Expanded settings into a desktop-style settings center with navigation, a selectable theme gallery, and a dedicated token editor.
- Added persisted editor typography controls, desktop system-font selection, content-width control, and plain-text ideographic first-line indentation.
