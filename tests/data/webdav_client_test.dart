import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zephyr/data/services/webdav_client.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

const session = CloudSyncSession(
  serverUrl: 'https://dav.jianguoyun.com/dav/',
  username: 'writer@example.com',
  appPassword: 'application-password',
);

void main() {
  test('connect verifies the WebDAV root with basic authentication', () async {
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'PROPFIND');
        expect(request.url.toString(), session.serverUrl);
        expect(request.headers['Depth'], '0');
        expect(
          request.headers['Authorization'],
          'Basic ${base64Encode(utf8.encode('writer@example.com:application-password'))}',
        );
        return http.Response('', 207);
      }),
    );
    addTearDown(client.close);
    await client.verifyConnection(session);
  });

  test(
    'rejects a non-HTTPS WebDAV endpoint before sending credentials',
    () async {
      var requests = 0;
      final client = WebDavClient(
        httpClient: MockClient((request) async {
          requests++;
          return http.Response('', 207);
        }),
      );
      addTearDown(client.close);
      await expectLater(
        client.verifyConnection(
          const CloudSyncSession(
            serverUrl: 'http://dav.jianguoyun.com/dav/',
            username: 'writer@example.com',
            appPassword: 'application-password',
          ),
        ),
        throwsFormatException,
      );
      expect(requests, 0);
    },
  );

  test('creates PureWriter and library folders at WebDAV root', () async {
    final requested = <String>[];
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        requested.add('${request.method} ${request.url}');
        return http.Response('', 201);
      }),
    );
    addTearDown(client.close);
    final folder = await client.ensureLibraryFolder(
      session: session,
      libraryId: 'library-id',
    );
    expect(folder, 'https://dav.jianguoyun.com/dav/PureWriter/library-id/');
    expect(requested, [
      'MKCOL https://dav.jianguoyun.com/dav/PureWriter/',
      'MKCOL https://dav.jianguoyun.com/dav/PureWriter/library-id/',
    ]);
  });

  test(
    'confirms existing folders after MKCOL reports method not allowed',
    () async {
      final requested = <String>[];
      final client = WebDavClient(
        httpClient: MockClient((request) async {
          requested.add(request.method);
          return http.Response('', request.method == 'MKCOL' ? 405 : 207);
        }),
      );
      addTearDown(client.close);
      await client.ensureLibraryFolder(
        session: session,
        libraryId: 'library-id',
      );
      expect(requested, ['MKCOL', 'PROPFIND', 'MKCOL', 'PROPFIND']);
    },
  );

  test('lists remote backups from a WebDAV multistatus response', () async {
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        expect(request.method, 'PROPFIND');
        expect(request.headers['Depth'], '1');
        return http.Response('''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:">
  <d:response><d:href>/dav/PureWriter/library-id/Backups/</d:href></d:response>
  <d:response>
    <d:href>/dav/PureWriter/library-id/Backups/backup.pwb</d:href>
    <d:propstat><d:prop>
      <d:getlastmodified>Tue, 01 Sep 2026 10:00:00 GMT</d:getlastmodified>
      <d:getcontentlength>123</d:getcontentlength>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>''', 207);
      }),
    );
    addTearDown(client.close);
    final entries = await client.listNamedBackups(
      session: session,
      libraryFolderId: 'https://dav.jianguoyun.com/dav/PureWriter/library-id/',
    );
    expect(entries, hasLength(1));
    expect(entries.single.fileName, 'backup.pwb');
    expect(entries.single.sizeBytes, 123);
    expect(
      entries.single.fileId,
      'https://dav.jianguoyun.com/dav/PureWriter/library-id/Backups/backup.pwb',
    );
  });

  test('uploads snapshot data before its manifest', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-webdav-');
    addTearDown(() => directory.delete(recursive: true));
    final pwb = File('${directory.path}/library.pwb');
    await pwb.writeAsString('snapshot');
    final uploaded = <String>[];
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        uploaded.add(request.url.pathSegments.last);
        return http.Response('', 201);
      }),
    );
    addTearDown(client.close);
    await client.uploadLibrarySnapshot(
      session: session,
      parentFileId: 'https://dav.jianguoyun.com/dav/PureWriter/library-id/',
      pwb: pwb,
      manifest: CloudSyncManifest(
        libraryId: 'library-id',
        updatedAt: DateTime.utc(2026, 9, 1),
        deviceName: 'test',
        appVersion: '0.1.0',
      ),
    );
    expect(uploaded, ['library.pwb', 'manifest.json']);
  });

  test('rejects an invalid remote manifest instead of replacing it', () async {
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        return http.Response('{"schema":1}', 200);
      }),
    );
    addTearDown(client.close);
    await expectLater(
      client.downloadManifest(
        session: session,
        parentFileId: 'https://dav.jianguoyun.com/dav/PureWriter/library-id/',
      ),
      throwsFormatException,
    );
  });

  test('uploads and downloads a named backup inside PureWriter', () async {
    final directory = await Directory.systemTemp.createTemp('zephyr-webdav-');
    addTearDown(() => directory.delete(recursive: true));
    final pwb = File('${directory.path}/backup.pwb');
    await pwb.writeAsString('backup bytes');
    final requests = <String>[];
    final client = WebDavClient(
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        return switch (request.method) {
          'MKCOL' || 'PUT' => http.Response('', 201),
          'GET' => http.Response('backup bytes', 200),
          _ => http.Response('', 500),
        };
      }),
    );
    addTearDown(client.close);
    const folder = 'https://dav.jianguoyun.com/dav/PureWriter/library-id/';
    await client.uploadNamedBackup(
      session: session,
      libraryFolderId: folder,
      pwb: pwb,
      fileName: 'backup.pwb',
    );
    final downloaded = await client.downloadBackupFile(
      session: session,
      entry: CloudBackupEntry(
        fileId: '${folder}Backups/backup.pwb',
        fileName: 'backup.pwb',
        modified: DateTime.utc(2026, 9, 1),
        sizeBytes: 12,
      ),
      staging: directory,
    );
    expect(await downloaded.readAsString(), 'backup bytes');
    expect(requests, [
      'MKCOL /dav/PureWriter/library-id/Backups/',
      'PUT /dav/PureWriter/library-id/Backups/backup.pwb',
      'GET /dav/PureWriter/library-id/Backups/backup.pwb',
    ]);
  });

  test(
    'refuses to download a backup outside the configured WebDAV root',
    () async {
      var requests = 0;
      final client = WebDavClient(
        httpClient: MockClient((request) async {
          requests++;
          return http.Response('', 200);
        }),
      );
      addTearDown(client.close);
      final directory = await Directory.systemTemp.createTemp('zephyr-webdav-');
      addTearDown(() => directory.delete(recursive: true));
      await expectLater(
        client.downloadBackupFile(
          session: session,
          entry: CloudBackupEntry(
            fileId: 'https://other.example/backup.pwb',
            fileName: 'backup.pwb',
            modified: DateTime.utc(2026, 9, 1),
            sizeBytes: 12,
          ),
          staging: directory,
        ),
        throwsFormatException,
      );
      expect(requests, 0);
    },
  );
}
