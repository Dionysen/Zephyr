# Zephyr

Zephyr is a cross-platform, local-first plain-text editor. It owns a PureWriter-compatible `App/Room.db` SQLite library, rather than an application-managed folder of text files.

Android is the first verified runtime; iOS, Windows, macOS and Linux hosts are included now.

`domain` holds platform-independent contracts, `data` owns the PureWriter v27 SQLite schema, and `ui` follows MVVM. Cloud synchronization and Git backup will be adapters over the library repository, never alternate sources of truth.

```sh
flutter run -d <android-device-id>
flutter test tests
```
