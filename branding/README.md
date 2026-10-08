# App icon

Master source (edit this) — keep it **full-bleed square** (no baked corner radius):

```
branding/app_icon.svg
```

Generate every platform icon — **same command on Windows / macOS / Linux**:

```bash
dart run tool/generate_app_icons.dart
```

That:

1. Rasterizes the SVG with Flutter (`flutter_svg`) — no ImageMagick / Inkscape needed
2. Writes:
   - `branding/app_icon.png` — 1024×1024 with **iOS continuous-corner** mask (~22.37% radius)
   - `branding/app_icon_square.png` — 1024×1024 full-bleed (for iOS / Android adaptive)
3. Runs `flutter_launcher_icons` (desktop/web use the rounded PNG; iOS/Android use the square PNG)

Requirements: Flutter SDK on `PATH` (`flutter` and `dart`).

## PNG-only workflow

If you already have a 1024×1024 PNG (and skip SVG rasterize), place the files you want the launcher to consume and run:

```bash
dart run tool/generate_app_icons.dart --skip-svg
```

`--skip-svg` does not re-apply the iOS mask; provide `app_icon.png` / `app_icon_square.png` as needed.
