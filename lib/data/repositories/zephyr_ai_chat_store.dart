import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_chat_session.dart';
import '../../domain/models/zephyr_meta_keys.dart';
import '../services/purewriter_database.dart';

/// Zephyr-only AI chat persistence in Room.db (included in `.pwb` backups).
class ZephyrAiChatStore {
  ZephyrAiChatStore(this._store, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final PureWriterDatabase _store;
  final Uuid _uuid;

  Database get _db => _store.database;

  Future<List<AiChatSession>> listSessions(
    String articleId, {
    bool includeArchived = false,
    bool onlyWithMessages = true,
  }) async {
    final rows = await _db.query(
      'ZephyrAiSession',
      where: includeArchived
          ? 'article_id = ?'
          : 'article_id = ? AND archived = 0',
      whereArgs: [articleId],
      orderBy: 'updated_at DESC',
    );
    final sessions = rows.map(_sessionFromRow).toList(growable: false);
    if (!onlyWithMessages) return sessions;
    final nonempty = <AiChatSession>[];
    for (final session in sessions) {
      if (await sessionHasMessages(session.id)) {
        nonempty.add(session);
      }
    }
    return nonempty;
  }

  Future<bool> sessionHasMessages(String sessionId) async {
    final count = Sqflite.firstIntValue(
      await _db.rawQuery(
        'SELECT COUNT(*) FROM ZephyrAiMessage WHERE session_id = ?',
        [sessionId],
      ),
    );
    return (count ?? 0) > 0;
  }

  Future<AiChatSession?> getSession(String sessionId) async {
    final rows = await _db.query(
      'ZephyrAiSession',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _sessionFromRow(rows.first);
  }

  Future<AiChatSession> createSession({
    required String articleId,
    String? title,
  }) async {
    _store.ensureWritable();
    final now = DateTime.now();
    final id = _uuid.v4();
    final session = AiChatSession(
      id: id,
      articleId: articleId,
      title: title?.trim().isNotEmpty == true ? title!.trim() : _defaultTitle(now),
      archived: false,
      contextSummary: '',
      createdAt: now,
      updatedAt: now,
    );
    await _db.insert('ZephyrAiSession', _sessionToRow(session));
    return session;
  }

  Future<void> updateSession(AiChatSession session) async {
    _store.ensureWritable();
    await _db.update(
      'ZephyrAiSession',
      _sessionToRow(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> setArchived(String sessionId, bool archived) async {
    _store.ensureWritable();
    final session = await getSession(sessionId);
    if (session == null) return;
    await updateSession(
      session.copyWith(
        archived: archived,
        updatedAt: DateTime.now(),
      ),
    );
  }

  static String scrollOffsetKey({
    required String articleId,
    String? sessionId,
  }) => sessionId ?? 'article:$articleId';

  Future<double?> readScrollOffset({
    required String articleId,
    String? sessionId,
  }) async {
    final map = await _readScrollMap();
    final key = scrollOffsetKey(articleId: articleId, sessionId: sessionId);
    final value = map[key];
    if (value == null) return null;
    return value;
  }

  Future<void> writeScrollOffset({
    required String articleId,
    String? sessionId,
    required double offset,
  }) async {
    _store.ensureWritable();
    final map = await _readScrollMap();
    final key = scrollOffsetKey(articleId: articleId, sessionId: sessionId);
    if (offset <= 0) {
      map.remove(key);
    } else {
      map[key] = offset;
    }
    await _writeScrollMap(map);
  }

  Future<void> clearScrollOffset(String key) async {
    _store.ensureWritable();
    final map = await _readScrollMap();
    if (!map.containsKey(key)) return;
    map.remove(key);
    await _writeScrollMap(map);
  }

  Future<void> deleteSession(String sessionId) async {
    _store.ensureWritable();
    final session = await getSession(sessionId);
    await clearScrollOffset(sessionId);
    await _db.transaction((txn) async {
      await txn.delete(
        'ZephyrAiMessage',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'ZephyrAiSession',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
    if (session != null) {
      final active = await readActiveSessionId(session.articleId);
      if (active == sessionId) {
        await clearActiveSessionId(session.articleId);
      }
    }
  }

  Future<List<AiChatStoredMessage>> listMessages(String sessionId) async {
    await _ensureModelBodyColumn();
    final rows = await _db.query(
      'ZephyrAiMessage',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(_messageFromRow).toList(growable: false);
  }

  Future<AiChatStoredMessage> appendMessage({
    required String sessionId,
    required AiChatMessageRole role,
    required String body,
    String thinking = '',
    String modelBody = '',
  }) async {
    _store.ensureWritable();
    await _ensureModelBodyColumn();
    final now = DateTime.now();
    final rows = await _db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) AS m FROM ZephyrAiMessage '
      'WHERE session_id = ?',
      [sessionId],
    );
    final nextOrder = ((rows.first['m'] as int?) ?? -1) + 1;
    final message = AiChatStoredMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: role,
      body: body,
      thinking: thinking,
      modelBody: modelBody,
      sortOrder: nextOrder,
      createdAt: now,
    );
    await _db.insert('ZephyrAiMessage', _messageToRow(message));
    final session = await getSession(sessionId);
    if (session != null) {
      await updateSession(session.copyWith(updatedAt: now));
    }
    return message;
  }

  Future<void> updateMessageBody({
    required String messageId,
    required String body,
    String thinking = '',
  }) async {
    _store.ensureWritable();
    await _db.update(
      'ZephyrAiMessage',
      {'body': body, 'thinking': thinking},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> deleteMessagesBeforeSortOrder({
    required String sessionId,
    required int keepFromSortOrder,
  }) async {
    _store.ensureWritable();
    await _db.delete(
      'ZephyrAiMessage',
      where: 'session_id = ? AND sort_order < ?',
      whereArgs: [sessionId, keepFromSortOrder],
    );
  }

  Future<String?> readActiveSessionId(String articleId) async {
    final map = await _readActiveMap();
    return map[articleId];
  }

  Future<void> setActiveSessionId(String articleId, String sessionId) async {
    _store.ensureWritable();
    final map = await _readActiveMap();
    map[articleId] = sessionId;
    await _writeActiveMap(map);
  }

  Future<void> clearActiveSessionId(String articleId) async {
    _store.ensureWritable();
    final map = await _readActiveMap();
    map.remove(articleId);
    await _writeActiveMap(map);
  }

  Future<void> deleteSessionIfEmpty(String sessionId) async {
    if (!await sessionHasMessages(sessionId)) {
      await deleteSession(sessionId);
    }
  }

  Future<void> purgeEmptySessions(String articleId) async {
    final rows = await _db.query(
      'ZephyrAiSession',
      columns: ['id'],
      where: 'article_id = ?',
      whereArgs: [articleId],
    );
    for (final row in rows) {
      final id = row['id'] as String?;
      if (id != null) await deleteSessionIfEmpty(id);
    }
  }

  /// Active session only when it has stored messages (welcome-only UI is not persisted).
  Future<AiChatSession?> loadActivePersistedSession(String articleId) async {
    final activeId = await readActiveSessionId(articleId);
    if (activeId == null) return null;
    final existing = await getSession(activeId);
    if (existing == null || existing.archived) {
      await clearActiveSessionId(articleId);
      return null;
    }
    if (!await sessionHasMessages(activeId)) {
      await deleteSession(activeId);
      await clearActiveSessionId(articleId);
      return null;
    }
    return existing;
  }

  Future<void> beginNewConversation(String articleId) async {
    _store.ensureWritable();
    final activeId = await readActiveSessionId(articleId);
    if (activeId != null) {
      await deleteSessionIfEmpty(activeId);
    }
    await clearActiveSessionId(articleId);
    await purgeEmptySessions(articleId);
  }

  Future<void> mergeFromBackupDatabase(Database backupDb) async {
    final localDb = _db;
    if (!await _hasTable(localDb, 'ZephyrAiSession') ||
        !await _hasTable(backupDb, 'ZephyrAiSession')) {
      return;
    }
    final remoteSessions = await backupDb.query('ZephyrAiSession');
    if (remoteSessions.isEmpty) return;
    final localTimes = <String, int>{
      for (final row in await localDb.query(
        'ZephyrAiSession',
        columns: ['id', 'updated_at'],
      ))
        row['id']! as String: (row['updated_at'] as int?) ?? 0,
    };
    await localDb.transaction((txn) async {
      for (final remote in remoteSessions) {
        final id = remote['id'] as String?;
        if (id == null) continue;
        final remoteTime = (remote['updated_at'] as int?) ?? 0;
        final localTime = localTimes[id];
        if (localTime != null && localTime > remoteTime) continue;
        await txn.insert(
          'ZephyrAiSession',
          remote,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.delete(
          'ZephyrAiMessage',
          where: 'session_id = ?',
          whereArgs: [id],
        );
        if (await _hasTable(backupDb, 'ZephyrAiMessage')) {
          final messages = await backupDb.query(
            'ZephyrAiMessage',
            where: 'session_id = ?',
            whereArgs: [id],
          );
          for (final message in messages) {
            await txn.insert(
              'ZephyrAiMessage',
              message,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
      final remoteMeta = await backupDb.query(
        'ZephyrMeta',
        where: 'key = ?',
        whereArgs: [ZephyrMetaKeys.aiChatActiveSession],
        limit: 1,
      );
      if (remoteMeta.isNotEmpty) {
        await txn.insert(
          'ZephyrMeta',
          remoteMeta.first,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final remoteScroll = await backupDb.query(
        'ZephyrMeta',
        where: 'key = ?',
        whereArgs: [ZephyrMetaKeys.aiChatScrollOffsets],
        limit: 1,
      );
      if (remoteScroll.isNotEmpty) {
        await txn.insert(
          'ZephyrMeta',
          remoteScroll.first,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Map<String, String>> _readActiveMap() async {
    final rows = await _db.query(
      'ZephyrMeta',
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.aiChatActiveSession],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } on Object {
      return {};
    }
  }

  Future<void> _writeActiveMap(Map<String, String> map) async {
    await _db.insert(
      'ZephyrMeta',
      {
        'key': ZephyrMetaKeys.aiChatActiveSession,
        'value': jsonEncode(map),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, double>> _readScrollMap() async {
    final rows = await _db.query(
      'ZephyrMeta',
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.aiChatScrollOffsets],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } on Object {
      return {};
    }
  }

  Future<void> _writeScrollMap(Map<String, double> map) async {
    await _db.insert(
      'ZephyrMeta',
      {
        'key': ZephyrMetaKeys.aiChatScrollOffsets,
        'value': jsonEncode(map),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  var _modelBodyReady = false;

  Future<void> _ensureModelBodyColumn() async {
    if (_modelBodyReady) return;
    final columns = await _db.rawQuery('PRAGMA table_info(ZephyrAiMessage)');
    final has = columns.any((column) => column['name'] == 'model_body');
    if (!has) {
      await _db.execute(
        "ALTER TABLE ZephyrAiMessage ADD COLUMN model_body TEXT NOT NULL DEFAULT ''",
      );
    }
    _modelBodyReady = true;
  }

  Future<bool> _hasTable(DatabaseExecutor database, String name) async =>
      (await database.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
        [name],
      )).isNotEmpty;

  static String _defaultTitle(DateTime now) {
    final local = now.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static AiChatSession _sessionFromRow(Map<String, Object?> row) => AiChatSession(
    id: row['id']! as String,
    articleId: row['article_id']! as String,
    title: row['title']! as String,
    archived: (row['archived'] as int?) == 1,
    contextSummary: row['context_summary'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
  );

  static Map<String, Object?> _sessionToRow(AiChatSession session) => {
    'id': session.id,
    'article_id': session.articleId,
    'title': session.title,
    'archived': session.archived ? 1 : 0,
    'context_summary': session.contextSummary,
    'created_at': session.createdAt.millisecondsSinceEpoch,
    'updated_at': session.updatedAt.millisecondsSinceEpoch,
  };

  static AiChatStoredMessage _messageFromRow(Map<String, Object?> row) =>
      AiChatStoredMessage(
        id: row['id']! as String,
        sessionId: row['session_id']! as String,
        role: row['role'] == 'user'
            ? AiChatMessageRole.user
            : AiChatMessageRole.assistant,
        body: row['body']! as String,
        thinking: row['thinking'] as String? ?? '',
        modelBody: row['model_body'] as String? ?? '',
        sortOrder: row['sort_order']! as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      );

  static Map<String, Object?> _messageToRow(AiChatStoredMessage message) => {
    'id': message.id,
    'session_id': message.sessionId,
    'role': message.role == AiChatMessageRole.user ? 'user' : 'assistant',
    'body': message.body,
    'model_body': message.modelBody,
    'thinking': message.thinking,
    'sort_order': message.sortOrder,
    'created_at': message.createdAt.millisecondsSinceEpoch,
  };
}
