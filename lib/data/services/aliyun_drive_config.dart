import '../../domain/models/cloud_sync.dart';

/// Resolves Aliyun Drive open-platform credentials.
///
/// Prefer release builds with `--dart-define=ALIYUN_DRIVE_CLIENT_ID=...` and
/// `ALIYUN_DRIVE_CLIENT_SECRET=...`. Developers waiting on approval can paste
/// credentials into the settings UI; those override dart-defines when present.
class AliyunDriveConfig {
  const AliyunDriveConfig({
    this.dartDefineClientId = const String.fromEnvironment(
      'ALIYUN_DRIVE_CLIENT_ID',
    ),
    this.dartDefineClientSecret = const String.fromEnvironment(
      'ALIYUN_DRIVE_CLIENT_SECRET',
    ),
  });

  final String dartDefineClientId;
  final String dartDefineClientSecret;

  AliyunDriveAppCredentials fromStored({
    String? storedClientId,
    String? storedClientSecret,
  }) {
    final id = (storedClientId != null && storedClientId.isNotEmpty)
        ? storedClientId
        : dartDefineClientId;
    final secret = (storedClientSecret != null && storedClientSecret.isNotEmpty)
        ? storedClientSecret
        : dartDefineClientSecret;
    return AliyunDriveAppCredentials(clientId: id, clientSecret: secret);
  }
}
