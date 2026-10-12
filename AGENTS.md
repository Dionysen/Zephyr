# Zephyr repository guidance

Read `docs/ARCHITECTURE.md` and `docs/DEVELOPMENT.md` before structural edits. This is a Flutter local-first plain-text editor backed by a PureWriter-compatible `App/Room.db`, not a directory of text files.

## Boundaries

- `packages/text_editor_foundation` is pure Dart. `packages/plain_text_editor` and `packages/flutter_primitives` may depend on Flutter but must never import `package:zephyr/...` or application-specific data, settings, localization, or theme.
- `lib/domain` owns business models and repository contracts. `lib/data` implements storage and services. `lib/ui/features` owns app UI and ViewModels; `lib/app` composes them.
- Put reusable pure text rules in `text_editor_foundation`, Flutter mechanisms in the other packages, and Zephyr styling/integrations in `lib/ui/core` or a feature. New application code imports package APIs directly; old paths are compatibility exports.
- Preserve the PureWriter v27 Room fingerprint, unknown-schema read-only behavior, `.zephyr-lock`, pending-edit flushes, and backup/restore semantics.

## Tests and changes

- Put tests under `tests/domain`, `tests/data`, or `tests/ui` (never `test/`). Use `flutter_test` and English behavior names. Initialize `TestWidgetsFlutterBinding` for layout or `TextPainter` tests.
- Use `addTearDown` for disposables and temporary resources; temporary directories come from `Directory.systemTemp.createTemp`.
- During refactors, do not weaken, skip, or rewrite existing test assertions to get a pass. Run affected files and `flutter test tests`.
- Run `flutter analyze lib packages tests` and `git diff --check`. Remove a file only after checking its references and build role.
- Preserve user-facing behavior and platform support. Document a new public package API or dependency boundary in `docs/ARCHITECTURE.md`.
