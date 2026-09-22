# Zephyr

Zephyr is a local-first, cross-platform plain-text editor. Its document library is a PureWriter-compatible SQLite `App/Room.db`, rather than a directory of application-managed text files.

The application uses a layered Flutter architecture: `domain` defines the platform-independent library contracts, `data` owns the PureWriter v27 storage protocol, and `ui` uses MVVM. Future backup and sync adapters must use the repository boundary rather than writing through the UI.

## Prerequisites

- Flutter SDK compatible with Dart `^3.13.4`.
- Run `flutter doctor` and address items relevant to the target platform.
- Windows development needs Visual Studio with the **Desktop development with C++** workload.
- Android development needs Android Studio, an Android SDK, and a device or emulator.
- iOS and macOS development require macOS with Xcode. iOS cannot be built on Windows.
- Linux development needs the Flutter Linux desktop toolchain; follow `flutter doctor` for the missing packages on the target distribution.

Verify the setup and list detected targets:

```powershell
flutter doctor
flutter devices
```

## Install dependencies

Run all commands from the repository root:

```powershell
cd C:\Users\zhaoys-c\Documents\Zephyr
flutter pub get
```

Run `flutter pub get` again whenever `pubspec.yaml` or `pubspec.lock` changes. Do not manually edit `pubspec.lock`.

## Run and debug

Use `flutter devices` to obtain a device identifier. The common commands are:

```powershell
# Windows desktop
flutter run -d windows

# Android device or running emulator
flutter run -d <android-device-id>

# iOS simulator or device, from macOS only
flutter run -d <ios-device-id>

# macOS desktop, from macOS only
flutter run -d macos

# Linux desktop, from Linux only
flutter run -d linux
```

For editor-based debugging, open the repository root in VS Code or Android Studio, select the intended Flutter device, and start `lib/main.dart` in Debug mode. Breakpoints work in Dart code for all supported native targets.

## Hot reload and restart

When the app is running through `flutter run`, focus the terminal and use:

- `r`: hot reloads changed Dart code while retaining in-memory state where possible.
- `R`: hot restarts the Flutter isolate and recreates application state. Local `Room.db` data is retained.
- `q`: stops the application.

Native host changes, dependency changes, and some plugin changes need a full stop followed by `flutter run`; hot reload cannot apply them.

## Tests and quality checks

The project keeps tests in `tests/`.

```powershell
# Run all unit and widget tests
flutter test tests

# Run one test file
flutter test tests\data\purewriter_database_test.dart

# Static analysis
flutter analyze

# Apply standard Dart formatting
dart format lib tests
```

Before handing off a change, run at least:

```powershell
flutter analyze
flutter test tests
```

## Build artifacts

Debug builds are normally produced automatically by `flutter run`. To produce a distributable build, use the platform-specific Flutter command on that platform, for example:

```powershell
# Windows
flutter build windows

# Android APK
flutter build apk
```

Build outputs live under `build/` and are intentionally not committed.

## PureWriter library safety

Zephyr can open a library root containing `App/Room.db`. It checks the v27 Room fingerprint before enabling writes; unknown schemas open read-only. Never edit the same library in PureWriter and Zephyr at the same time. Zephyr uses `.zephyr-lock` to prevent multiple Zephyr writers, but PureWriter does not participate in that lock protocol.
