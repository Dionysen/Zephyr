# Changelog

## Unreleased

- Load system fonts only when the editor settings page opens, reuse the hidden settings window, and make editor settings scroll instead of overflowing in smaller windows.
- Fixed the settings child window startup by using its registered multi-window controller instead of the main-window-only plugin.
- Open settings in a dedicated non-modal desktop window and synchronize saved appearance and editor preferences with the writing window.
- Fixed editor startup notifications during widget construction and made history snapshots conditional on the compatible `History` table being present.

## 0.1.0 - Unreleased

- Created the cross-platform Zephyr foundation with a PureWriter v27-compatible `App/Room.db` library, article list and autosaving editor shell.
- Reworked the desktop editor shell into an immersive sidebar workspace with animated sidebar visibility, book selection, volume and chapter navigation, and a floating library-directory switcher.
- Applied Vellum-aligned dark shell tokens for quiet editor surfaces, compact typography, subtle outlines, and layered sidebar navigation.
- Fixed a desktop shell assertion caused by assigning duplicate corner-shape configuration to navigation surfaces.
- Added persistent, user-editable writing-shell theme tokens and a settings dialog opened from the library dock.
- Expanded settings into a desktop-style settings center with navigation, a selectable theme gallery, and a dedicated token editor.
- Added persisted editor typography controls, desktop system-font selection, content-width control, and plain-text ideographic first-line indentation.
