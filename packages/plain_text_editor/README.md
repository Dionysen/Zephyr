# plain_text_editor

Reusable Flutter plain-text editing engine. Import `package:plain_text_editor/plain_text_editor.dart` for the public API, or a focused library such as `package:plain_text_editor/layout/plain_text_layout_engine.dart`.

The package owns document/selection state, IME input, paragraph layout, gestures, decorations and render objects. Pure Dart text rules come from `text_editor_foundation`. It has no Zephyr application dependency. The host supplies a Widget shell, theme, persistence, shortcuts and accessibility context.
