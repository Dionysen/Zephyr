import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/article_editor_state.dart';
import '../../domain/models/zephyr_meta_keys.dart';
import '../services/purewriter_database.dart';

/// Persists per-chapter editor viewport/caret in [ZephyrMeta] (`.pwb` / cloud).
class ZephyrArticleEditorStateStore {
  ZephyrArticleEditorStateStore(this._store);

  final PureWriterDatabase _store;

  Database get _db => _store.database;

  Future<Map<String, ArticleEditorState>> readAll() async {
    final rows = await _db.query(
      'ZephyrMeta',
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.articleEditorStates],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, ArticleEditorState>{};
      for (final entry in decoded.entries) {
        final state = ArticleEditorState.fromJson(entry.value);
        if (state != null) {
          out[entry.key] = state;
        }
      }
      return out;
    } on Object {
      return {};
    }
  }

  Future<ArticleEditorState?> read(String articleId) async {
    final all = await readAll();
    return all[articleId];
  }

  Future<void> write({
    required String articleId,
    required ArticleEditorState state,
  }) async {
    _store.ensureWritable();
    final map = await readAll();
    map[articleId] = state;
    await _writeAll(map);
  }

  Future<void> remove(String articleId) async {
    _store.ensureWritable();
    final map = await readAll();
    if (!map.containsKey(articleId)) return;
    map.remove(articleId);
    await _writeAll(map);
  }

  Future<void> mergeFromBackupDatabase(Database backupDb) async {
    final localDb = _db;
    if (!await _hasTable(localDb, 'ZephyrMeta') ||
        !await _hasTable(backupDb, 'ZephyrMeta')) {
      return;
    }
    final remoteRows = await backupDb.query(
      'ZephyrMeta',
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.articleEditorStates],
      limit: 1,
    );
    if (remoteRows.isEmpty) return;
    final remoteRaw = remoteRows.first['value'] as String?;
    if (remoteRaw == null || remoteRaw.isEmpty) return;
    Map<String, ArticleEditorState> remoteMap;
    try {
      final decoded = jsonDecode(remoteRaw) as Map<String, dynamic>;
      remoteMap = {};
      for (final entry in decoded.entries) {
        final state = ArticleEditorState.fromJson(entry.value);
        if (state != null) {
          remoteMap[entry.key] = state;
        }
      }
    } on Object {
      return;
    }
    if (remoteMap.isEmpty) return;

    final localMap = await readAll();
    for (final entry in remoteMap.entries) {
      localMap[entry.key] = ArticleEditorState.merge(
        localMap[entry.key],
        entry.value,
      )!;
    }
    await _writeAll(localMap);
  }

  Future<void> _writeAll(Map<String, ArticleEditorState> map) async {
    final encoded = jsonEncode({
      for (final entry in map.entries) entry.key: entry.value.toJson(),
    });
    await _db.insert(
      'ZephyrMeta',
      {
        'key': ZephyrMetaKeys.articleEditorStates,
        'value': encoded,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> _hasTable(Database db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );
    return rows.isNotEmpty;
  }
}
