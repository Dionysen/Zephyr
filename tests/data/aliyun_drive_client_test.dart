import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zephyr/data/services/aliyun_drive_client.dart';
import 'package:zephyr/domain/models/cloud_sync.dart';

void main() {
  const credentials = AliyunDriveAppCredentials(
    clientId: 'app-id',
    clientSecret: 'app-secret',
  );
  final session = CloudSyncSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    driveId: 'drive',
  );

  test(
    'QR challenge sends app credentials and reads returned challenge',
    () async {
      final requests = <http.Request>[];
      final client = AliyunDriveClient(
        credentials: credentials,
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'sid': 'session-id',
              'qrCodeUrl': 'https://example.test/qr',
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final challenge = await client.createQrChallenge();

      expect(challenge.sid, 'session-id');
      expect(challenge.qrCodeUrl, 'https://example.test/qr');
      expect(requests.single.url.path, '/oauth/authorize/qrcode');
      expect(
        jsonDecode(requests.single.body),
        containsPair('client_id', 'app-id'),
      );
      expect(requests.single.headers, isNot(contains('Authorization')));
    },
  );

  test('unconfigured QR login fails before sending a request', () async {
    var requests = 0;
    final client = AliyunDriveClient(
      credentials: const AliyunDriveAppCredentials(
        clientId: '',
        clientSecret: '',
      ),
      httpClient: MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);

    await expectLater(client.createQrChallenge(), throwsStateError);
    expect(requests, 0);
  });

  test(
    'QR polling maps server statuses and unknown status to failed',
    () async {
      final responses = [
        'waitLogin',
        'scanSuccess',
        'loginSuccess',
        'expired',
        'other',
      ];
      var index = 0;
      final client = AliyunDriveClient(
        credentials: credentials,
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'status': responses[index++], 'authCode': 'code'}),
            200,
          ),
        ),
      );
      addTearDown(client.close);

      final statuses = <AliyunDriveQrStatus>[];
      for (var i = 0; i < responses.length; i++) {
        statuses.add((await client.pollQrStatus('sid')).status);
      }
      expect(statuses, [
        AliyunDriveQrStatus.waiting,
        AliyunDriveQrStatus.scanned,
        AliyunDriveQrStatus.success,
        AliyunDriveQrStatus.expired,
        AliyunDriveQrStatus.failed,
      ]);
    },
  );

  test(
    'backup listing filters files, follows pages, and sorts newest first',
    () async {
      final markers = <String?>[];
      final client = AliyunDriveClient(
        credentials: credentials,
        httpClient: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['parent_file_id'] == 'library') {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'name': 'Backups',
                    'type': 'folder',
                    'file_id': 'backup-dir',
                  },
                ],
              }),
              200,
            );
          }
          markers.add(body['marker'] as String?);
          if (body['marker'] == null) {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'name': 'old.pwb',
                    'type': 'file',
                    'file_id': 'old',
                    'updated_at': '2026-01-01T00:00:00Z',
                    'size': 3,
                  },
                  {'name': 'ignore.txt', 'type': 'file', 'file_id': 'ignore'},
                ],
                'next_marker': 'next',
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'name': 'new.PWB',
                  'type': 'file',
                  'file_id': 'new',
                  'updated_at': '2026-02-01T00:00:00Z',
                  'size': 4.9,
                },
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final backups = await client.listNamedBackups(
        session: session,
        libraryFolderId: 'library',
      );

      expect(markers, [null, 'next']);
      expect(backups.map((entry) => entry.fileId), ['new', 'old']);
      expect(backups.first.sizeBytes, 4);
    },
  );

  test('API errors and invalid JSON surface as request failures', () async {
    final responses = [
      http.Response('{"code":"Forbidden","message":"denied"}', 403),
      http.Response('not json', 200),
    ];
    var index = 0;
    final client = AliyunDriveClient(
      credentials: credentials,
      httpClient: MockClient((request) async => responses[index++]),
    );
    addTearDown(client.close);

    await expectLater(client.pollQrStatus('sid'), throwsStateError);
    await expectLater(client.pollQrStatus('sid'), throwsStateError);
  });

  test(
    'snapshot upload sends the database and manifest as separate files',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'zephyr-drive-upload-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final archive = File('${directory.path}/library.pwb');
      await archive.writeAsBytes([1, 2, 3]);
      final uploadedNames = <String>[];
      final client = AliyunDriveClient(
        credentials: credentials,
        httpClient: MockClient((request) async {
          expect(request.url.path, '/adrive/v1.0/openFile/create');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          uploadedNames.add(body['name'] as String);
          expect(body['parent_file_id'], 'folder');
          expect(body['check_name_mode'], 'overwrite');
          return http.Response('{"rapid_upload":true}', 200);
        }),
      );
      addTearDown(client.close);
      final manifest = CloudSyncManifest(
        libraryId: 'library',
        updatedAt: DateTime.utc(2026, 1, 1),
        deviceName: 'device',
        appVersion: '0.1.0',
      );

      await client.uploadLibrarySnapshot(
        session: session,
        parentFileId: 'folder',
        pwb: archive,
        manifest: manifest,
      );

      expect(uploadedNames, ['library.pwb', 'manifest.json']);
    },
  );

  test(
    'manifest download resolves file metadata and decodes its contents',
    () async {
      final manifest = CloudSyncManifest(
        libraryId: 'library',
        updatedAt: DateTime.utc(2026, 1, 1),
        deviceName: 'device',
        appVersion: '0.1.0',
      );
      final client = AliyunDriveClient(
        credentials: credentials,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/openFile/list')) {
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'name': 'manifest.json',
                    'type': 'file',
                    'file_id': 'manifest-id',
                  },
                ],
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/openFile/getDownloadUrl')) {
            expect(
              jsonDecode(request.body),
              containsPair('file_id', 'manifest-id'),
            );
            return http.Response(
              '{"url":"https://download.example.test/manifest"}',
              200,
            );
          }
          expect(request.url.host, 'download.example.test');
          return http.Response(jsonEncode(manifest.toJson()), 200);
        }),
      );
      addTearDown(client.close);

      final downloaded = await client.downloadManifest(
        session: session,
        parentFileId: 'folder',
      );

      expect(downloaded?.libraryId, 'library');
      expect(downloaded?.deviceName, 'device');
      expect(
        downloaded?.updatedAt.millisecondsSinceEpoch,
        manifest.updatedAt.millisecondsSinceEpoch,
      );
    },
  );
}
