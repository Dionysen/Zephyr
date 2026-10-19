import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared secure storage for WebDAV credentials and LLM API keys.
///
/// macOS defaults to the data-protection keychain, which returns
/// errSecMissingEntitlement (-34018) unless the binary carries
/// keychain-access-groups. Ad-hoc debug builds do not. The login keychain
/// stores the same secrets without that entitlement. iOS is unchanged.
///
/// Debug `flutter run` on macOS uses [MacOsDebugKeyValueSecureStore] instead
/// (see [zephyr_key_value_secure_store.dart]) to avoid Keychain password prompts
/// when the ad-hoc signature changes each build.
const zephyrSecureStorage = FlutterSecureStorage(
  mOptions: MacOsOptions(usesDataProtectionKeychain: false),
);
