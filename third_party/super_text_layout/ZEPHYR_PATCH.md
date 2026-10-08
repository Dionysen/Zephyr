# Zephyr patch notes (`super_text_layout`)

Vendored from `super_text_layout` 0.1.22.

## Why

With `TextStyle.height` > 1.0, upstream selection painting uses
`BoxHeightStyle.max` plus a 2px vertical expansion. Adjacent line highlight
rects overlap, which shows as darker bands under a translucent selection color.

## Changes

In `lib/src/text_selection_layer.dart`:

1. `BoxHeightStyle.max` → `BoxHeightStyle.includeLineSpacingMiddle`
2. `selectionHighlightBoxVerticalExpansion` `2.0` → `0.0`

Re-check when upgrading `super_editor` / `super_text_layout`.
