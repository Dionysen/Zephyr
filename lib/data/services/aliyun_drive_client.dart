import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../domain/models/cloud_sync.dart';

/// Thin Aliyun Drive OpenAPI client (https://openapi.aliyundrive.com).
class AliyunDriveClient {
  AliyunDriveClient({
    required this.credentials,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  static const _apiBase = 'https://openapi.aliyundrive.com';
  static const _scopes = ['user:base', 'file:all:read', 'file:all:write'];

  final AliyunDriveAppCredentials credentials;
  final http.Client _http;

  bool get isConfigured => credentials.isConfigured;

  void close() => _http.close();

  Future<AliyunDriveQrChallenge> createQrChallenge() async {
    _ensureConfigured();
    final body = await _postJson(
      '$_apiBase/oauth/authorize/qrcode',
      {
        'client_id': credentials.clientId,
        'client_secret': credentials.clientSecret,
        'scopes': _scopes,
      },
      authorized: false,
    );
    final sid = body['sid'] as String?;
    final url = body['qrCodeUrl'] as String?;
    if (sid == null || url == null) {
      throw StateError('Aliyun Drive QR response missing sid/qrCodeUrl.');
    }
    return AliyunDriveQrChallenge(sid: sid, qrCodeUrl: url);
  }

  Future<AliyunDriveQrPollResult> pollQrStatus(String sid) async {
    final response = await _http.get(
      Uri.parse('$_apiBase/oauth/qrcode/$sid/status'),
    );
    final body = _decodeMap(response);
    final statusRaw = (body['status'] as String? ?? '').toLowerCase();
    final authCode = body['authCode'] as String?;
    final status = switch (statusRaw) {
      'waitlogin' || 'waiting' => AliyunDriveQrStatus.waiting,
      'scansuccess' || 'scanned' => AliyunDriveQrStatus.scanned,
      'loginsuccess' || 'success' => AliyunDriveQrStatus.success,
      'expired' || 'qrcodeexpired' => AliyunDriveQrStatus.expired,
      _ => AliyunDriveQrStatus.failed,
    };
    return AliyunDriveQrPollResult(status: status, authCode: authCode);
  }

  Future<CloudSyncSession> exchangeAuthCode(String authCode) async {
    _ensureConfigured();
    final body = await _postJson('$_apiBase/oauth/access_token', {
      'client_id': credentials.clientId,
      'client_secret': credentials.clientSecret,
      'grant_type': 'authorization_code',
      'code': authCode,
    }, authorized: false);
    return _sessionFromTokenBody(body);
  }

  Future<CloudSyncSession> refresh(String refreshToken) async {
    _ensureConfigured();
    final body = await _postJson('$_apiBase/oauth/access_token', {
      'client_id': credentials.clientId,
      'client_secret': credentials.clientSecret,
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    }, authorized: false);
    return _sessionFromTokenBody(body);
  }

  Future<CloudSyncSession> _sessionFromTokenBody(
    Map<String, dynamic> body,
  ) async {
    final access = body['access_token'] as String?;
    final refresh = body['refresh_token'] as String?;
    final expiresIn = body['expires_in'];
    if (access == null || refresh == null || expiresIn is! int) {
      throw StateError('Aliyun Drive token response incomplete.');
    }
    final drive = await getDriveInfo(access);
    final user = await getUserProfile(access);
    return CloudSyncSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      driveId: drive,
      displayName: user.$1,
      avatarUrl: user.$2,
    );
  }

  Future<String> getDriveInfo(String accessToken) async {
    final body = await _postJson(
      '$_apiBase/adrive/v1.0/user/getDriveInfo',
      const {},
      accessToken: accessToken,
    );
    final driveId =
        body['default_drive_id'] as String? ?? body['resource_drive_id'] as String?;
    if (driveId == null || driveId.isEmpty) {
      throw StateError('Aliyun Drive getDriveInfo missing drive id.');
    }
    return driveId;
  }

  Future<(String name, String avatar)> getUserProfile(String accessToken) async {
    try {
      final response = await _http.get(
        Uri.parse('$_apiBase/oauth/users/info'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      final body = _decodeMap(response);
      return (
        body['name'] as String? ?? body['nick_name'] as String? ?? '',
        body['avatar'] as String? ?? '',
      );
    } on Object {
      return ('', '');
    }
  }

  /// Ensures `Zephyr/libraries/{libraryId}` exists under the drive root.
  Future<String> ensureLibraryFolder({
    required CloudSyncSession session,
    required String libraryId,
  }) async {
    final zephyrId = await _ensureChildFolder(
      session: session,
      parentFileId: 'root',
      name: 'Zephyr',
    );
    final librariesId = await _ensureChildFolder(
      session: session,
      parentFileId: zephyrId,
      name: 'libraries',
    );
    return _ensureChildFolder(
      session: session,
      parentFileId: librariesId,
      name: libraryId,
    );
  }

  Future<String> _ensureChildFolder({
    required CloudSyncSession session,
    required String parentFileId,
    required String name,
  }) async {
    final existing = await _findChild(
      session: session,
      parentFileId: parentFileId,
      name: name,
      type: 'folder',
    );
    if (existing != null) return existing;
    try {
      final body = await _postJson(
        '$_apiBase/adrive/v1.0/openFile/create',
        {
          'drive_id': session.driveId,
          'parent_file_id': parentFileId,
          'name': name,
          'type': 'folder',
          'check_name_mode': 'refuse',
        },
        accessToken: session.accessToken,
      );
      final fileId = body['file_id'] as String?;
      if (fileId != null) return fileId;
    } on Object {
      // AlreadyExists / race — fall through to lookup.
    }
    final again = await _findChild(
      session: session,
      parentFileId: parentFileId,
      name: name,
      type: 'folder',
    );
    if (again != null) return again;
    throw StateError('Failed to create folder "$name".');
  }

  Future<String?> _findChild({
    required CloudSyncSession session,
    required String parentFileId,
    required String name,
    required String type,
  }) async {
    var marker = '';
    do {
      final body = await _postJson(
        '$_apiBase/adrive/v1.0/openFile/list',
        {
          'drive_id': session.driveId,
          'parent_file_id': parentFileId,
          'limit': 100,
          if (marker.isNotEmpty) 'marker': marker,
        },
        accessToken: session.accessToken,
      );
      final items = body['items'] as List<dynamic>? ?? const [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        if (map['name'] == name && map['type'] == type) {
          return map['file_id'] as String?;
        }
      }
      marker = body['next_marker'] as String? ?? '';
    } while (marker.isNotEmpty);
    return null;
  }

  Future<CloudSyncManifest?> downloadManifest({
    required CloudSyncSession session,
    required String parentFileId,
  }) async {
    final fileId = await _findChild(
      session: session,
      parentFileId: parentFileId,
      name: 'manifest.json',
      type: 'file',
    );
    if (fileId == null) return null;
    final bytes = await downloadFileBytes(session: session, fileId: fileId);
    final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return CloudSyncManifest.fromJson(map);
  }

  Future<File?> downloadLibraryPwb({
    required CloudSyncSession session,
    required String parentFileId,
    required Directory staging,
  }) async {
    final fileId = await _findChild(
      session: session,
      parentFileId: parentFileId,
      name: 'library.pwb',
      type: 'file',
    );
    if (fileId == null) return null;
    final bytes = await downloadFileBytes(session: session, fileId: fileId);
    final out = File(path.join(staging.path, 'library.pwb'));
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  Future<Uint8List> downloadFileBytes({
    required CloudSyncSession session,
    required String fileId,
  }) async {
    final meta = await _postJson(
      '$_apiBase/adrive/v1.0/openFile/getDownloadUrl',
      {'drive_id': session.driveId, 'file_id': fileId},
      accessToken: session.accessToken,
    );
    final url = meta['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Aliyun Drive download URL missing.');
    }
    final response = await _http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Download failed (${response.statusCode}).');
    }
    return response.bodyBytes;
  }

  Future<void> uploadLibrarySnapshot({
    required CloudSyncSession session,
    required String parentFileId,
    required File pwb,
    required CloudSyncManifest manifest,
  }) async {
    await _uploadFile(
      session: session,
      parentFileId: parentFileId,
      name: 'library.pwb',
      bytes: await pwb.readAsBytes(),
    );
    final manifestBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    await _uploadFile(
      session: session,
      parentFileId: parentFileId,
      name: 'manifest.json',
      bytes: Uint8List.fromList(manifestBytes),
    );
  }

  /// Ensures `Backups/` under the library folder and uploads [pwb] with [fileName].
  Future<void> uploadNamedBackup({
    required CloudSyncSession session,
    required String libraryFolderId,
    required File pwb,
    required String fileName,
  }) async {
    final backupsId = await _ensureChildFolder(
      session: session,
      parentFileId: libraryFolderId,
      name: 'Backups',
    );
    await _uploadFile(
      session: session,
      parentFileId: backupsId,
      name: fileName,
      bytes: await pwb.readAsBytes(),
    );
  }

  Future<List<CloudBackupEntry>> listNamedBackups({
    required CloudSyncSession session,
    required String libraryFolderId,
  }) async {
    final backupsId = await _findChild(
      session: session,
      parentFileId: libraryFolderId,
      name: 'Backups',
      type: 'folder',
    );
    if (backupsId == null) return const [];
    final entries = <CloudBackupEntry>[];
    var marker = '';
    do {
      final body = await _postJson(
        '$_apiBase/adrive/v1.0/openFile/list',
        {
          'drive_id': session.driveId,
          'parent_file_id': backupsId,
          'limit': 100,
          if (marker.isNotEmpty) 'marker': marker,
        },
        accessToken: session.accessToken,
      );
      final items = body['items'] as List<dynamic>? ?? const [];
      for (final item in items) {
        final map = item as Map<String, dynamic>;
        if (map['type'] != 'file') continue;
        final name = map['name'] as String? ?? '';
        if (!name.toLowerCase().endsWith('.pwb')) continue;
        final fileId = map['file_id'] as String?;
        if (fileId == null) continue;
        final updated = map['updated_at'] as String?;
        final size = map['size'];
        entries.add(
          CloudBackupEntry(
            fileId: fileId,
            fileName: name,
            modified: updated == null
                ? DateTime.now()
                : DateTime.tryParse(updated)?.toLocal() ?? DateTime.now(),
            sizeBytes: size is int ? size : (size is num ? size.toInt() : 0),
          ),
        );
      }
      marker = body['next_marker'] as String? ?? '';
    } while (marker.isNotEmpty);
    entries.sort((a, b) => b.modified.compareTo(a.modified));
    return entries;
  }

  Future<File> downloadBackupFile({
    required CloudSyncSession session,
    required CloudBackupEntry entry,
    required Directory staging,
  }) async {
    final bytes = await downloadFileBytes(
      session: session,
      fileId: entry.fileId,
    );
    final out = File(path.join(staging.path, entry.fileName));
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  Future<void> _uploadFile({
    required CloudSyncSession session,
    required String parentFileId,
    required String name,
    required Uint8List bytes,
  }) async {
    final create = await _postJson(
      '$_apiBase/adrive/v1.0/openFile/create',
      {
        'drive_id': session.driveId,
        'parent_file_id': parentFileId,
        'name': name,
        'type': 'file',
        'check_name_mode': 'overwrite',
        'size': bytes.length,
        'part_info_list': [
          {'part_number': 1},
        ],
      },
      accessToken: session.accessToken,
    );
    if (create['rapid_upload'] == true) {
      return;
    }
    final uploadId = create['upload_id'] as String?;
    final fileId = create['file_id'] as String?;
    final parts = create['part_info_list'] as List<dynamic>? ?? const [];
    if (uploadId == null || fileId == null || parts.isEmpty) {
      throw StateError('Aliyun Drive create upload incomplete for $name.');
    }
    final uploadUrl =
        (parts.first as Map<String, dynamic>)['upload_url'] as String?;
    if (uploadUrl == null) {
      throw StateError('Aliyun Drive upload_url missing for $name.');
    }
    final put = await _http.put(Uri.parse(uploadUrl), body: bytes);
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw StateError('Aliyun Drive part upload failed (${put.statusCode}).');
    }
    await _postJson(
      '$_apiBase/adrive/v1.0/openFile/complete',
      {
        'drive_id': session.driveId,
        'file_id': fileId,
        'upload_id': uploadId,
      },
      accessToken: session.accessToken,
    );
  }

  Future<Map<String, dynamic>> _postJson(
    String url,
    Object body, {
    String? accessToken,
    bool authorized = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json;charset=UTF-8',
    };
    if (authorized) {
      final token = accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Aliyun Drive request missing access token.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await _http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'raw': decoded};
    } on Object {
      throw StateError(
        'Aliyun Drive bad JSON (${response.statusCode}): ${response.body}',
      );
    }
    final code = body['code'] as String?;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        (code != null && code.isNotEmpty)) {
      final message = body['message'] as String? ?? response.body;
      throw StateError('Aliyun Drive error: ${code ?? response.statusCode} $message');
    }
    return body;
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Aliyun Drive AppId/AppSecret not configured. '
        'Paste them in Settings after open-platform approval, or pass '
        'ALIYUN_DRIVE_CLIENT_ID / ALIYUN_DRIVE_CLIENT_SECRET dart-defines.',
      );
    }
  }
}
