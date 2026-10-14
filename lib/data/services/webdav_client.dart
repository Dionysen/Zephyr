import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../../domain/models/cloud_sync.dart';

/// WebDAV file operations for one configured account.
class WebDavClient {
  WebDavClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  void close() => _http.close();

  Uri _root(CloudSyncSession session) {
    final uri = Uri.tryParse(session.serverUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Enter a valid HTTPS WebDAV URL.');
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  Uri _child(Uri parent, String name) {
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains('\\')) {
      throw const FormatException('Invalid WebDAV file name.');
    }
    return parent.replace(
      pathSegments: [
        ...parent.pathSegments.where((part) => part.isNotEmpty),
        name,
      ],
    );
  }

  Uri _folder(Uri parent, String name) {
    final child = _child(parent, name);
    return child.replace(path: '${child.path}/');
  }

  Map<String, String> _headers(CloudSyncSession session) => {
    'Authorization':
        'Basic ${base64Encode(utf8.encode('${session.username}:${session.appPassword}'))}',
  };

  Future<http.Response> _request(
    CloudSyncSession session,
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    List<int>? body,
  }) async {
    final request = http.Request(method, uri)
      ..headers.addAll(_headers(session))
      ..headers.addAll(headers)
      ..followRedirects = false;
    if (body != null) request.bodyBytes = body;
    final streamed = await _http.send(request);
    return http.Response.fromStream(streamed);
  }

  void _expect(http.Response response, Set<int> statuses) {
    if (!statuses.contains(response.statusCode)) {
      throw HttpException('WebDAV request failed (${response.statusCode}).');
    }
  }

  Future<void> verifyConnection(CloudSyncSession session) async {
    final response = await _request(
      session,
      'PROPFIND',
      _root(session),
      headers: const {'Depth': '0'},
    );
    _expect(response, {207});
  }

  Future<String> ensureLibraryFolder({
    required CloudSyncSession session,
  }) async {
    final folder = _folder(_root(session), 'Zephyr');
    await _ensureFolder(session, folder);
    return folder.toString();
  }

  /// Detects any pre-existing content whose library ID cannot be verified.
  Future<bool> hasUntrackedContent({
    required CloudSyncSession session,
    required String parentFileId,
  }) async {
    final folder = Uri.parse(parentFileId);
    final response = await _request(
      session,
      'PROPFIND',
      folder,
      headers: const {'Depth': '1'},
    );
    _expect(response, {207});
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    for (final item in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'response',
    )) {
      final href = _firstText(item, 'href');
      if (href == null) continue;
      final uri = folder.resolve(href);
      if (uri.scheme == folder.scheme &&
          uri.host == folder.host &&
          uri.port == folder.port &&
          uri.path.startsWith(folder.path) &&
          uri.path != folder.path) {
        return true;
      }
    }
    return false;
  }

  Future<void> _ensureFolder(CloudSyncSession session, Uri uri) async {
    final response = await _request(session, 'MKCOL', uri);
    if (response.statusCode == 201) return;
    if (response.statusCode == 405) {
      final existing = await _request(
        session,
        'PROPFIND',
        uri,
        headers: const {'Depth': '0'},
      );
      _expect(existing, {207});
      return;
    }
    _expect(response, {201});
  }

  Future<CloudSyncManifest?> downloadManifest({
    required CloudSyncSession session,
    required String parentFileId,
  }) async {
    final response = await _request(
      session,
      'GET',
      _child(Uri.parse(parentFileId), 'manifest.json'),
    );
    if (response.statusCode == 404) return null;
    _expect(response, {200});
    final manifest = CloudSyncManifest.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
    if (manifest == null) {
      throw const FormatException('Invalid cloud manifest.');
    }
    return manifest;
  }

  Future<File?> downloadLibraryPwb({
    required CloudSyncSession session,
    required String parentFileId,
    required Directory staging,
  }) async {
    final response = await _request(
      session,
      'GET',
      _child(Uri.parse(parentFileId), 'library.pwb'),
    );
    if (response.statusCode == 404) return null;
    _expect(response, {200});
    final out = File(path.join(staging.path, 'library.pwb'));
    await out.writeAsBytes(response.bodyBytes, flush: true);
    return out;
  }

  Future<void> uploadLibrarySnapshot({
    required CloudSyncSession session,
    required String parentFileId,
    required File pwb,
    required CloudSyncManifest manifest,
  }) async {
    final folder = Uri.parse(parentFileId);
    await _putFile(session, _child(folder, 'library.pwb'), pwb);
    final response = await _request(
      session,
      'PUT',
      _child(folder, 'manifest.json'),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: utf8.encode(jsonEncode(manifest.toJson())),
    );
    _expect(response, {200, 201, 204});
  }

  Future<void> uploadSettingsBundle({
    required CloudSyncSession session,
    required String parentFileId,
    required List<int> bytes,
  }) async {
    final response = await _request(
      session,
      'PUT',
      _child(Uri.parse(parentFileId), 'settings.json'),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: bytes,
    );
    _expect(response, {200, 201, 204});
  }

  /// Returns null when the remote settings file is missing.
  Future<List<int>?> downloadSettingsBundle({
    required CloudSyncSession session,
    required String parentFileId,
  }) async {
    final response = await _request(
      session,
      'GET',
      _child(Uri.parse(parentFileId), 'settings.json'),
    );
    if (response.statusCode == 404) return null;
    _expect(response, {200});
    return response.bodyBytes;
  }

  Future<void> uploadNamedBackup({
    required CloudSyncSession session,
    required String libraryFolderId,
    required File pwb,
    required String fileName,
  }) async {
    final folder = _folder(Uri.parse(libraryFolderId), 'Backups');
    await _ensureFolder(session, folder);
    await _putFile(session, _child(folder, fileName), pwb);
  }

  Future<void> _putFile(CloudSyncSession session, Uri uri, File file) async {
    final response = await _request(
      session,
      'PUT',
      uri,
      headers: const {'Content-Type': 'application/octet-stream'},
      body: await file.readAsBytes(),
    );
    _expect(response, {200, 201, 204});
  }

  Future<List<CloudBackupEntry>> listNamedBackups({
    required CloudSyncSession session,
    required String libraryFolderId,
  }) async {
    final folder = _folder(Uri.parse(libraryFolderId), 'Backups');
    final response = await _request(
      session,
      'PROPFIND',
      folder,
      headers: const {'Depth': '1', 'Content-Type': 'application/xml'},
      body: utf8.encode(
        '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/><d:getcontentlength/><d:getlastmodified/></d:prop></d:propfind>',
      ),
    );
    if (response.statusCode == 404) return [];
    _expect(response, {207});
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));
    final entries = <CloudBackupEntry>[];
    for (final item in document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'response',
    )) {
      final href = _firstText(item, 'href');
      if (href == null) continue;
      final uri = folder.resolve(href);
      if (uri == folder ||
          uri.path.endsWith('/') ||
          uri.scheme != folder.scheme ||
          uri.host != folder.host ||
          uri.port != folder.port ||
          !uri.path.startsWith(folder.path)) {
        continue;
      }
      final name = uri.pathSegments.last;
      if (!name.toLowerCase().endsWith('.pwb')) continue;
      final modified = HttpDate.parse(
        _firstText(item, 'getlastmodified') ??
            HttpDate.format(DateTime.now().toUtc()),
      );
      final size =
          int.tryParse(_firstText(item, 'getcontentlength') ?? '') ?? 0;
      entries.add(
        CloudBackupEntry(
          fileId: uri.toString(),
          fileName: name,
          modified: modified,
          sizeBytes: size,
        ),
      );
    }
    entries.sort((a, b) => b.modified.compareTo(a.modified));
    return entries;
  }

  /// Deletes a history file only when it belongs directly to this account's
  /// `Zephyr/Backups` folder. The latest `library.pwb` is never targeted.
  Future<void> deleteNamedBackup({
    required CloudSyncSession session,
    required CloudBackupEntry entry,
  }) async {
    final folder = _folder(_folder(_root(session), 'Zephyr'), 'Backups');
    final expected = _child(folder, entry.fileName);
    if (!entry.fileName.startsWith('Zephyr-') ||
        !entry.fileName.toLowerCase().endsWith('.pwb') ||
        entry.fileId != expected.toString()) {
      throw const FormatException('Backup is outside this WebDAV account.');
    }
    final response = await _request(session, 'DELETE', expected);
    _expect(response, {200, 202, 204, 404});
  }

  String? _firstText(XmlElement root, String name) {
    for (final element in root.descendants.whereType<XmlElement>()) {
      if (element.name.local == name) return element.innerText;
    }
    return null;
  }

  Future<File> downloadBackupFile({
    required CloudSyncSession session,
    required CloudBackupEntry entry,
    required Directory staging,
  }) async {
    final uri = Uri.parse(entry.fileId);
    final root = _root(session);
    final backupRoot = _folder(_folder(root, 'Zephyr'), 'Backups');
    if (uri.scheme != root.scheme ||
        uri.host != root.host ||
        uri.port != root.port ||
        !uri.path.startsWith(backupRoot.path) ||
        path.basename(uri.path) != entry.fileName ||
        entry.fileName == '.' ||
        entry.fileName == '..' ||
        entry.fileName.contains('/') ||
        entry.fileName.contains('\\')) {
      throw const FormatException('Backup is outside this WebDAV account.');
    }
    final response = await _request(session, 'GET', uri);
    _expect(response, {200});
    final out = File(path.join(staging.path, entry.fileName));
    await out.writeAsBytes(response.bodyBytes, flush: true);
    return out;
  }
}
