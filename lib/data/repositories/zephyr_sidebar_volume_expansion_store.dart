import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/sidebar_volume_expansion.dart';
import '../../domain/models/zephyr_meta_keys.dart';
import '../services/purewriter_database.dart';

/// Persists per-book volume expand/collapse in [ZephyrMeta] (`.pwb` / cloud).
class ZephyrSidebarVolumeExpansionStore {
  ZephyrSidebarVolumeExpansionStore(this._store);

  final PureWriterDatabase _store;

  Database get _db => _store.database;

  Future<Map<String, SidebarVolumeExpansionEntry>> readAll() async {
    final rows = await _db.query(
      'ZephyrMeta',
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.sidebarVolumeExpansionByBook],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, SidebarVolumeExpansionEntry>{};
      for (final entry in decoded.entries) {
        final state = SidebarVolumeExpansionEntry.fromJson(entry.value);
        if (state != null) {
          out[entry.key] = state;
        }
      }
      return out;
    } on Object {
      return {};
    }
  }

  Future<Map<String, Set<String>>> readExpandedSetsByBook() async {
    final all = await readAll();
    return {
      for (final entry in all.entries) entry.key: entry.value.toExpandedSet(),
    };
  }

  Future<void> replaceAll(Map<String, Set<String>> byBook) async {
    _store.ensureWritable();
    final existing = await readAll();
    final now = DateTime.now().millisecondsSinceEpoch;
    final next = <String, SidebarVolumeExpansionEntry>{};
    for (final entry in byBook.entries) {
      final prior = existing[entry.key];
      final sortedNew = entry.value.toList(growable: false)..sort();
      final sortedOld = List<String>.from(
        prior?.expandedVolumeIds ?? const [],
      )..sort();
      if (prior != null && sortedOld.toString() == sortedNew.toString()) {
        next[entry.key] = prior;
      } else {
        next[entry.key] = SidebarVolumeExpansionEntry(
          expandedVolumeIds: entry.value.toList(growable: false),
          updatedAt: now,
        );
      }
    }
    await _writeAll(next);
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
      whereArgs: [ZephyrMetaKeys.sidebarVolumeExpansionByBook],
      limit: 1,
    );
    if (remoteRows.isEmpty) return;
    final remoteRaw = remoteRows.first['value'] as String?;
    if (remoteRaw == null || remoteRaw.isEmpty) return;
    Map<String, SidebarVolumeExpansionEntry> remoteMap;
    try {
      final decoded = jsonDecode(remoteRaw) as Map<String, dynamic>;
      remoteMap = {};
      for (final entry in decoded.entries) {
        final state = SidebarVolumeExpansionEntry.fromJson(entry.value);
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
      localMap[entry.key] = SidebarVolumeExpansionEntry.merge(
        localMap[entry.key],
        entry.value,
      )!;
    }
    await _writeAll(localMap);
  }

  Future<void> _writeAll(Map<String, SidebarVolumeExpansionEntry> map) async {
    final encoded = jsonEncode({
      for (final entry in map.entries) entry.key: entry.value.toJson(),
    });
    await _db.insert(
      'ZephyrMeta',
      {
        'key': ZephyrMetaKeys.sidebarVolumeExpansionByBook,
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
