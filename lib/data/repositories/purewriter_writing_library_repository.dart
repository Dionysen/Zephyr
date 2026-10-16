import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/ai_chat_session.dart';
import '../../domain/models/library_backup.dart';
import '../../domain/models/purewriter_models.dart';
import '../../domain/models/quick_toolbar_config.dart';
import '../../domain/models/zephyr_meta_keys.dart';
import '../../domain/repositories/writing_library_repository.dart';
import '../../domain/use_cases/article_preview_summary.dart';
import '../services/device_label.dart';
import '../services/purewriter_database.dart';
import 'zephyr_ai_chat_store.dart';

class PureWriterWritingLibraryRepository implements WritingLibraryRepository {
  PureWriterWritingLibraryRepository(this._store, {Uuid? uuid})
    : _uuid = uuid ?? Uuid(),
      _aiChat = ZephyrAiChatStore(_store, uuid: uuid);
  final PureWriterDatabase _store;
  final Uuid _uuid;
  final ZephyrAiChatStore _aiChat;

  @override
  LibraryLocation? get location => _store.location;

  @override
  Future<LibraryLocation> openLibrary(String rootPath) =>
      _store.openLibrary(rootPath, createIfMissing: true);

  @override
  Future<LibraryLocation> openDefaultLibrary() => _store.openDefaultLibrary();

  @override
  Future<void> closeLibrary() => _store.close();

  @override
  Future<WritingLibrary> loadLibrary() async {
    final db = _store.database;
    final folders = await db.query(
      'Folder',
      where: 'deleted = 0',
      orderBy: 'rank ASC, createdTime ASC',
    );
    final articles = await db.query(
      'Article',
      where: 'deleted = 0',
      orderBy: 'orderKey ASC, rank ASC, updateTime DESC',
    );
    return WritingLibrary(
      folders: folders
          .map(
            (row) => WritingFolder(
              id: row['id']! as String,
              name: row['name']! as String,
              rank: row['rank']! as int,
              description: row['description'] as String? ?? '',
              tags: row['tags'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      categories:
          (await db.query(
                'Category',
                where: 'deleted = 0',
                orderBy: 'orderKey ASC, rank ASC',
              ))
              .map(
                (row) => WritingCategory(
                  id: row['id']! as String,
                  folderId: row['folderId']! as String,
                  name: row['name']! as String,
                  rank: row['rank']! as int,
                  collapsed: (row['collapsed']! as int) != 0,
                ),
              )
              .toList(growable: false),
      articles: articles.map(_summary).toList(growable: false),
    );
  }

  @override
  Future<WritingArticle> getArticle(String id) async {
    final rows = await _store.database.query(
      'Article',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('PureWriter article not found: $id');
    final row = rows.single;
    return WritingArticle(
      id: id,
      title: row['title']! as String,
      content: row['content']! as String,
      summary: row['summary'] as String? ?? '',
      folderId: row['folderId']! as String,
      categoryId: row['categoryId'] as String?,
      createdAt: _date(row['createTime']! as int),
      updatedAt: _date(row['updateTime']! as int),
      wordCount: row['count'] as int? ?? 0,
    );
  }

  @override
  Future<List<WritingArticle>> loadArticlesForSearch({
    String? folderId,
    String? categoryId,
    String? articleId,
    bool unfiledOnly = false,
    bool includeTrash = false,
  }) async {
    final db = _store.database;
    final where = StringBuffer('deleted = 0');
    final args = <Object?>[];
    if (articleId != null) {
      where.write(' AND id = ?');
      args.add(articleId);
    } else if (folderId != null && categoryId != null) {
      where.write(' AND folderId = ? AND categoryId = ?');
      args.addAll([folderId, categoryId]);
    } else if (folderId != null && unfiledOnly) {
      where.write(' AND folderId = ? AND categoryId IS NULL');
      args.add(folderId);
    } else if (folderId != null) {
      where.write(' AND folderId = ?');
      args.add(folderId);
    } else if (!includeTrash) {
      where.write(' AND folderId != ?');
      args.add(WritingFolder.trashId);
    }
    final rows = await db.query(
      'Article',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'orderKey ASC, rank ASC, updateTime DESC',
    );
    return [
      for (final row in rows)
        WritingArticle(
          id: row['id']! as String,
          title: row['title']! as String,
          content: row['content']! as String,
          summary: row['summary'] as String? ?? '',
          folderId: row['folderId']! as String,
          categoryId: row['categoryId'] as String?,
          createdAt: _date(row['createTime']! as int),
          updatedAt: _date(row['updateTime']! as int),
          wordCount: row['count'] as int? ?? 0,
        ),
    ];
  }

  @override
  Future<WritingArticle> createArticle({
    required String folderId,
    String? categoryId,
    String? afterArticleId,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final rank = await _insertRank(
      db: db,
      table: 'Article',
      folderId: folderId,
      afterId: afterArticleId,
    );
    await db.insert('Article', {
      'id': id,
      'title': 'Untitled',
      'content': '',
      'summary': '',
      'count': 0,
      'extension': 'txt',
      'preview': 0,
      'preview1': 0,
      'updateTime': now,
      'createTime': now,
      'folderId': folderId,
      'categoryId': categoryId,
      'editorId': 0,
      'rank': rank,
      'titleUpdateTime': now,
      'rankUpdateTime': now,
      'folderIdUpdateTime': now,
      'categoryIdUpdateTime': now,
      'extensionUpdateTime': 0,
      'deleted': 0,
      'deletedTime': 0,
      'autoChapter': 1,
      'autoChapterUpdateTime': 0,
      'orderKey': _orderKey(rank),
      'structureUpdateTime': now,
    });
    return getArticle(id);
  }

  @override
  Future<void> renameArticle({
    required String articleId,
    required String title,
  }) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final trimmed = title.trim().isEmpty ? 'Untitled' : title.trim();
    await _store.database.transaction((transaction) async {
      final rows = await transaction.query(
        'Article',
        where: 'id = ? AND deleted = 0',
        whereArgs: [articleId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('PureWriter article not found: $articleId');
      }
      final original = rows.single;
      if (original['title'] == trimmed) return;
      if (await _hasHistoryTable(transaction)) {
        await transaction.insert('History', _historySnapshot(original, now));
      }
      await transaction.update(
        'Article',
        {'title': trimmed, 'titleUpdateTime': now, 'updateTime': now},
        where: 'id = ?',
        whereArgs: [articleId],
      );
    });
  }

  @override
  Future<void> saveArticle(WritingArticle article) async {
    _store.ensureWritable();
    await _store.database.transaction((transaction) async {
      final rows = await transaction.query(
        'Article',
        where: 'id = ?',
        whereArgs: [article.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('PureWriter article not found: ${article.id}');
      }
      final original = rows.single;
      if (original['content'] == article.content) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (await _hasHistoryTable(transaction)) {
        await transaction.insert('History', _historySnapshot(original, now));
      }
      await transaction.update(
        'Article',
        {
          'content': article.content,
          'summary': articlePreviewSummary(article.content),
          'count': _count(article.content),
          'updateTime': now,
        },
        where: 'id = ?',
        whereArgs: [article.id],
      );
    });
    await clearDraft(article.id);
  }

  ArticleSummary _summary(Map<String, Object?> row) => ArticleSummary(
    id: row['id']! as String,
    title: row['title']! as String,
    summary: row['summary'] as String? ?? '',
    folderId: row['folderId']! as String,
    categoryId: row['categoryId'] as String?,
    createdAt: _date(row['createTime']! as int),
    updatedAt: _date(row['updateTime']! as int),
    wordCount: row['count'] as int? ?? 0,
  );
  DateTime _date(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds);
  int _count(String content) =>
      content.runes.where((rune) => rune != 10 && rune != 13).length;

  Future<bool> _hasHistoryTable(DatabaseExecutor database) async =>
      (await database.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'History' LIMIT 1",
      )).isNotEmpty;

  Map<String, Object?> _historySnapshot(
    Map<String, Object?> article,
    int now,
  ) => {
    'createTime': now,
    'article_id': article['id'],
    'article_title': article['title'],
    'article_content': article['content'],
    'article_summary': article['summary'],
    'article_count': article['count'],
    'article_extension': article['extension'],
    'article_preview': article['preview'],
    'article_preview1': article['preview1'],
    'article_updateTime': article['updateTime'],
    'article_createTime': article['createTime'],
    'article_folderId': article['folderId'],
    'article_categoryId': article['categoryId'],
    'article_editorId': article['editorId'],
    'article_rank': article['rank'],
    'article_titleUpdateTime': article['titleUpdateTime'],
    'article_rankUpdateTime': article['rankUpdateTime'],
    'article_folderIdUpdateTime': article['folderIdUpdateTime'],
    'article_categoryIdUpdateTime': article['categoryIdUpdateTime'],
    'article_extensionUpdateTime': article['extensionUpdateTime'],
    'article_deleted': article['deleted'],
    'article_deletedTime': article['deletedTime'],
    'article_autoChapter': article['autoChapter'],
    'article_autoChapterUpdateTime': article['autoChapterUpdateTime'],
    'article_orderKey': article['orderKey'],
    'article_structureUpdateTime': article['structureUpdateTime'],
  };

  @override
  Future<WritingCategory> createCategory({
    required String folderId,
    required String name,
    String? afterCategoryId,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final trimmed = name.trim().isEmpty ? 'Untitled' : name.trim();
    final rank = await _insertRank(
      db: db,
      table: 'Category',
      folderId: folderId,
      afterId: afterCategoryId,
    );
    await db.insert('Category', {
      'id': id,
      'folderId': folderId,
      'name': trimmed,
      'createdTime': now,
      'collapsed': 0,
      'rank': rank,
      'rankUpdateTime': now,
      'folderIdUpdateTime': now,
      'updateTime': now,
      'deleted': 0,
      'deletedTime': 0,
      'orderKey': _orderKey(rank),
      'structureUpdateTime': now,
    });
    return WritingCategory(
      id: id,
      folderId: folderId,
      name: trimmed,
      rank: rank,
      collapsed: false,
    );
  }

  @override
  Future<void> renameCategory({
    required String categoryId,
    required String name,
  }) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final trimmed = name.trim().isEmpty ? 'Untitled' : name.trim();
    final updated = await _store.database.update(
      'Category',
      {'name': trimmed, 'updateTime': now},
      where: 'id = ? AND deleted = 0',
      whereArgs: [categoryId],
    );
    if (updated == 0) {
      throw StateError('PureWriter category not found: $categoryId');
    }
  }

  @override
  Future<void> deleteCategory({
    required String categoryId,
    required bool deleteArticles,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'Category',
      columns: ['id', 'folderId'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('PureWriter category not found: $categoryId');
    }
    final articles = await db.query(
      'Article',
      columns: ['id'],
      where: 'categoryId = ? AND deleted = 0',
      whereArgs: [categoryId],
    );
    await db.transaction((txn) async {
      if (deleteArticles) {
        for (final article in articles) {
          await txn.update(
            'Article',
            {
              'folderId': PureWriterDatabase.trashFolderId,
              'folderIdUpdateTime': now,
              'structureUpdateTime': now,
              'updateTime': now,
            },
            where: 'id = ?',
            whereArgs: [article['id']],
          );
        }
      } else {
        await txn.update(
          'Article',
          {
            'categoryId': null,
            'categoryIdUpdateTime': now,
            'structureUpdateTime': now,
            'updateTime': now,
          },
          where: 'categoryId = ? AND deleted = 0',
          whereArgs: [categoryId],
        );
      }
      await txn.update(
        'Category',
        {
          'deleted': 1,
          'deletedTime': now,
          'updateTime': now,
          'structureUpdateTime': now,
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  @override
  Future<void> moveArticleToCategory({
    required String articleId,
    String? categoryId,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'Article',
      columns: ['id', 'folderId'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [articleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('PureWriter article not found: $articleId');
    }
    final folderId = rows.single['folderId']! as String;
    final maxRank = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Article WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    final rank = (maxRank.single['value']! as int) + 1;
    await db.update(
      'Article',
      {
        'categoryId': categoryId,
        'categoryIdUpdateTime': now,
        'rank': rank,
        'rankUpdateTime': now,
        'orderKey': _orderKey(rank),
        'structureUpdateTime': now,
        'updateTime': now,
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  @override
  Future<void> moveArticleToFolder({
    required String articleId,
    required String folderId,
  }) async {
    _store.ensureWritable();
    if (folderId == WritingFolder.trashId) {
      throw ArgumentError('Use trashArticle to move into trash.');
    }
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'Article',
      columns: ['id', 'folderId'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [articleId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('PureWriter article not found: $articleId');
    }
    if (rows.single['folderId'] == folderId) return;
    final folderRows = await db.query(
      'Folder',
      columns: ['id'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [folderId],
      limit: 1,
    );
    if (folderRows.isEmpty) {
      throw StateError('PureWriter folder not found: $folderId');
    }
    final maxRank = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Article WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    final rank = (maxRank.single['value']! as int) + 1;
    await db.update(
      'Article',
      {
        'folderId': folderId,
        'folderIdUpdateTime': now,
        'categoryId': null,
        'categoryIdUpdateTime': now,
        'rank': rank,
        'rankUpdateTime': now,
        'orderKey': _orderKey(rank),
        'structureUpdateTime': now,
        'updateTime': now,
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  @override
  Future<void> moveCategoryToFolder({
    required String categoryId,
    required String folderId,
  }) async {
    _store.ensureWritable();
    if (folderId == WritingFolder.trashId) {
      throw ArgumentError('Volumes cannot be moved into trash.');
    }
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'Category',
      columns: ['id', 'folderId'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('PureWriter category not found: $categoryId');
    }
    final sourceFolderId = rows.single['folderId']! as String;
    if (sourceFolderId == folderId) return;
    final folderRows = await db.query(
      'Folder',
      columns: ['id'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [folderId],
      limit: 1,
    );
    if (folderRows.isEmpty) {
      throw StateError('PureWriter folder not found: $folderId');
    }
    final maxCategoryRank = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Category WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    final categoryRank = (maxCategoryRank.single['value']! as int) + 1;
    final articles = await db.query(
      'Article',
      columns: ['id'],
      where: 'categoryId = ? AND deleted = 0',
      whereArgs: [categoryId],
      orderBy: 'orderKey ASC, rank ASC',
    );
    final maxArticleRank = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Article WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    var nextArticleRank = (maxArticleRank.single['value']! as int) + 1;
    await db.transaction((txn) async {
      await txn.update(
        'Category',
        {
          'folderId': folderId,
          'folderIdUpdateTime': now,
          'rank': categoryRank,
          'rankUpdateTime': now,
          'orderKey': _orderKey(categoryRank),
          'structureUpdateTime': now,
          'updateTime': now,
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      for (final row in articles) {
        final rank = nextArticleRank++;
        await txn.update(
          'Article',
          {
            'folderId': folderId,
            'folderIdUpdateTime': now,
            'rank': rank,
            'rankUpdateTime': now,
            'orderKey': _orderKey(rank),
            'structureUpdateTime': now,
            'updateTime': now,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    });
  }

  @override
  Future<WritingFolder> convertCategoryToFolder({
    required String categoryId,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'Category',
      columns: ['id', 'name'],
      where: 'id = ? AND deleted = 0',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('PureWriter category not found: $categoryId');
    }
    final rawName = (rows.single['name'] as String?)?.trim() ?? '';
    final bookName = rawName.isEmpty ? 'Untitled' : rawName;
    final articles = await db.query(
      'Article',
      columns: ['id'],
      where: 'categoryId = ? AND deleted = 0',
      whereArgs: [categoryId],
      orderBy: 'orderKey ASC, rank ASC',
    );
    final folderId = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final maxRows = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), -1) AS value FROM Folder '
      'WHERE deleted = 0 AND id != ?',
      [WritingFolder.trashId],
    );
    final folderRank = (maxRows.single['value']! as int) + 1;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE Folder SET rank = ?, rankUpdateTime = ?, updateTime = ? '
        'WHERE id = ? AND deleted = 0 AND rank <= ?',
        [folderRank + 1, now, now, WritingFolder.trashId, folderRank],
      );
      await txn.insert('Folder', {
        'id': folderId,
        'name': bookName,
        'createdTime': now,
        'description': '',
        'rank': folderRank,
        'deleted': 0,
        'deletedTime': 0,
        'updateTime': now,
        'rankUpdateTime': now,
        'autoChapter': 0,
        'autoChapterUpdateTime': 0,
        'autoChapterResetForCategory': 0,
        'autoChapterResetForCategoryUpdateTime': 0,
        'autoChapterReplaceBadPrefix': 0,
        'autoChapterReplaceBadPrefixUpdateTime': 0,
        'tags': '',
        'tagsUpdateTime': now,
        'rankModeUpdateTime': 0,
      });
      var articleRank = 1;
      for (final row in articles) {
        final rank = articleRank++;
        await txn.update(
          'Article',
          {
            'folderId': folderId,
            'folderIdUpdateTime': now,
            'categoryId': null,
            'categoryIdUpdateTime': now,
            'rank': rank,
            'rankUpdateTime': now,
            'orderKey': _orderKey(rank),
            'structureUpdateTime': now,
            'updateTime': now,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
      await txn.update(
        'Category',
        {
          'deleted': 1,
          'deletedTime': now,
          'updateTime': now,
          'structureUpdateTime': now,
        },
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
    return WritingFolder(
      id: folderId,
      name: bookName,
      rank: folderRank,
      description: '',
      tags: '',
    );
  }

  @override
  Future<void> reorderCategories({
    required String folderId,
    required List<String> orderedIds,
  }) async {
    _store.ensureWritable();
    await _rewriteOrder(
      table: 'Category',
      folderId: folderId,
      orderedIds: orderedIds,
    );
  }

  @override
  Future<void> reorderArticles({
    required String folderId,
    String? categoryId,
    required List<String> orderedIds,
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final all = await db.query(
      'Article',
      columns: ['id', 'categoryId'],
      where: 'folderId = ? AND deleted = 0',
      whereArgs: [folderId],
      orderBy: 'orderKey ASC, rank ASC',
    );
    final groupIds = all
        .where((row) => row['categoryId'] == categoryId)
        .map((row) => row['id']! as String)
        .toList();
    if (groupIds.length != orderedIds.length ||
        !groupIds.toSet().containsAll(orderedIds)) {
      throw ArgumentError('orderedIds must match the article group exactly');
    }
    final reordered = List<String>.from(orderedIds);
    var groupIndex = 0;
    final merged = <String>[
      for (final row in all)
        if (row['categoryId'] == categoryId)
          reordered[groupIndex++]
        else
          row['id']! as String,
    ];
    await db.transaction((txn) async {
      for (var i = 0; i < merged.length; i++) {
        final rank = i + 1;
        await txn.update(
          'Article',
          {
            'rank': rank,
            'orderKey': _orderKey(rank),
            'rankUpdateTime': now,
            'structureUpdateTime': now,
          },
          where: 'id = ?',
          whereArgs: [merged[i]],
        );
      }
    });
  }

  String _orderKey(int rank) => rank.toString().padLeft(12, '0');

  Future<int> _insertRank({
    required DatabaseExecutor db,
    required String table,
    required String folderId,
    String? afterId,
  }) async {
    if (afterId == null) {
      final result = await db.rawQuery(
        'SELECT COALESCE(MAX(rank), 0) AS value FROM $table WHERE folderId = ? AND deleted = 0',
        [folderId],
      );
      return (result.single['value']! as int) + 1;
    }
    final afterRows = await db.query(
      table,
      columns: ['rank'],
      where: 'id = ? AND folderId = ? AND deleted = 0',
      whereArgs: [afterId, folderId],
      limit: 1,
    );
    if (afterRows.isEmpty) {
      throw StateError('PureWriter $table not found: $afterId');
    }
    final afterRank = afterRows.single['rank']! as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final later = await db.query(
      table,
      columns: ['id', 'rank'],
      where: 'folderId = ? AND deleted = 0 AND rank > ?',
      whereArgs: [folderId, afterRank],
      orderBy: 'rank DESC',
    );
    for (final row in later) {
      final nextRank = (row['rank']! as int) + 1;
      await db.update(
        table,
        {
          'rank': nextRank,
          'orderKey': _orderKey(nextRank),
          'rankUpdateTime': now,
          'structureUpdateTime': now,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    return afterRank + 1;
  }

  Future<void> _rewriteOrder({
    required String table,
    required String folderId,
    required List<String> orderedIds,
  }) async {
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query(
      table,
      columns: ['id'],
      where: 'folderId = ? AND deleted = 0',
      whereArgs: [folderId],
      orderBy: 'orderKey ASC, rank ASC',
    );
    final existingIds = existing.map((row) => row['id']! as String).toList();
    if (existingIds.length != orderedIds.length ||
        !existingIds.toSet().containsAll(orderedIds)) {
      throw ArgumentError('orderedIds must match $table rows in the folder');
    }
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        final rank = i + 1;
        await txn.update(
          table,
          {
            'rank': rank,
            'orderKey': _orderKey(rank),
            'rankUpdateTime': now,
            'structureUpdateTime': now,
            if (table == 'Category') 'updateTime': now,
          },
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

  @override
  Future<void> updateFolder({
    required String folderId,
    required String name,
    String? description,
    String? tags,
  }) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final values = <String, Object?>{
      'name': name.trim().isEmpty ? 'Untitled' : name.trim(),
      'updateTime': now,
    };
    if (description != null) {
      values['description'] = description;
    }
    if (tags != null) {
      values['tags'] = tags;
      values['tagsUpdateTime'] = now;
    }
    final updated = await _store.database.update(
      'Folder',
      values,
      where: 'id = ? AND deleted = 0',
      whereArgs: [folderId],
    );
    if (updated == 0) {
      throw StateError('PureWriter folder not found: $folderId');
    }
  }

  @override
  Future<WritingFolder> createFolder({
    required String name,
    String description = '',
    String tags = '',
  }) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final trimmed = name.trim().isEmpty ? 'Untitled' : name.trim();
    final maxRows = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), -1) AS value FROM Folder '
      'WHERE deleted = 0 AND id != ?',
      [WritingFolder.trashId],
    );
    final rank = (maxRows.single['value']! as int) + 1;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE Folder SET rank = ?, rankUpdateTime = ?, updateTime = ? '
        'WHERE id = ? AND deleted = 0 AND rank <= ?',
        [rank + 1, now, now, WritingFolder.trashId, rank],
      );
      await txn.insert('Folder', {
        'id': id,
        'name': trimmed,
        'createdTime': now,
        'description': description,
        'rank': rank,
        'deleted': 0,
        'deletedTime': 0,
        'updateTime': now,
        'rankUpdateTime': now,
        'autoChapter': 0,
        'autoChapterUpdateTime': 0,
        'autoChapterResetForCategory': 0,
        'autoChapterResetForCategoryUpdateTime': 0,
        'autoChapterReplaceBadPrefix': 0,
        'autoChapterReplaceBadPrefixUpdateTime': 0,
        'tags': tags,
        'tagsUpdateTime': now,
        'rankModeUpdateTime': 0,
      });
    });
    return WritingFolder(
      id: id,
      name: trimmed,
      rank: rank,
      description: description,
      tags: tags,
    );
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    if (folderId == WritingFolder.trashId) {
      throw StateError('Cannot delete the trash folder.');
    }
    _store.ensureWritable();
    final db = _store.database;
    final articles = await db.query(
      'Article',
      columns: ['id'],
      where: 'folderId = ? AND deleted = 0',
      whereArgs: [folderId],
      limit: 1,
    );
    if (articles.isNotEmpty) {
      throw FolderNotEmptyException(folderId);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.update(
        'Category',
        {'deleted': 1, 'deletedTime': now, 'updateTime': now},
        where: 'folderId = ? AND deleted = 0',
        whereArgs: [folderId],
      );
      final updated = await txn.update(
        'Folder',
        {'deleted': 1, 'deletedTime': now, 'updateTime': now},
        where: 'id = ? AND deleted = 0',
        whereArgs: [folderId],
      );
      if (updated == 0) {
        throw StateError('PureWriter folder not found: $folderId');
      }
    });
  }

  @override
  Future<void> reorderFolders({required List<String> orderedIds}) async {
    _store.ensureWritable();
    final db = _store.database;
    final existing = await db.query(
      'Folder',
      columns: ['id'],
      where: 'deleted = 0 AND id != ?',
      whereArgs: [WritingFolder.trashId],
      orderBy: 'rank ASC, createdTime ASC',
    );
    final existingIds = existing.map((row) => row['id']! as String).toList();
    if (existingIds.length != orderedIds.length ||
        !existingIds.toSet().containsAll(orderedIds)) {
      throw ArgumentError('orderedIds must match non-trash Folder rows');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'Folder',
          {'rank': i, 'rankUpdateTime': now, 'updateTime': now},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
      await txn.update(
        'Folder',
        {'rank': orderedIds.length, 'rankUpdateTime': now, 'updateTime': now},
        where: 'id = ? AND deleted = 0',
        whereArgs: [WritingFolder.trashId],
      );
    });
  }

  @override
  Future<void> trashArticle(String articleId) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _store.database.update(
      'Article',
      {
        'folderId': PureWriterDatabase.trashFolderId,
        'folderIdUpdateTime': now,
        'structureUpdateTime': now,
        'updateTime': now,
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  @override
  Future<void> restoreArticle(
    String articleId, {
    required String folderId,
  }) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _store.database.update(
      'Article',
      {
        'folderId': folderId,
        'folderIdUpdateTime': now,
        'structureUpdateTime': now,
        'updateTime': now,
      },
      where: 'id = ?',
      whereArgs: [articleId],
    );
  }

  @override
  Future<List<ArticleHistory>> listHistory(String articleId) async =>
      !(await _hasHistoryTable(_store.database))
      ? const []
      : (await _store.database.query(
              'History',
              columns: ['createTime', 'article_content', 'article_title'],
              where: 'article_id = ?',
              whereArgs: [articleId],
              orderBy: 'createTime DESC',
            ))
            .map(
              (row) => ArticleHistory(
                createdAt: _date(row['createTime']! as int),
                content: row['article_content'] as String? ?? '',
                title: row['article_title'] as String?,
              ),
            )
            .toList(growable: false);

  @override
  Future<List<DailyWriting>> listDaily() async =>
      (await _store.database.query(
            'Daily',
            columns: [
              'year',
              'month',
              'day',
              'articleId',
              'wordCount',
              'updatedAt',
            ],
            orderBy: 'updatedAt DESC',
          ))
          .map(
            (row) => DailyWriting(
              day: DateTime(
                row['year']! as int,
                row['month']! as int,
                row['day']! as int,
              ),
              articleId: row['articleId']! as String,
              wordCount: row['wordCount']! as int,
              updatedAt: _date(row['updatedAt']! as int),
            ),
          )
          .toList(growable: false);

  @override
  Future<Map<String, double>> readScrolls() => _store.readScrolls();

  @override
  Future<void> writeScroll(String articleId, double offset) =>
      _store.writeScroll(articleId, offset);

  @override
  Future<void> restoreHistory({
    required String articleId,
    required DateTime createdAt,
  }) async {
    _store.ensureWritable();
    if (!await _hasHistoryTable(_store.database)) {
      throw StateError('History table is not available.');
    }
    final rows = await _store.database.query(
      'History',
      columns: ['article_content', 'article_title'],
      where: 'article_id = ? AND createTime = ?',
      whereArgs: [articleId, createdAt.millisecondsSinceEpoch],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('History revision not found.');
    }
    final article = await getArticle(articleId);
    await saveArticle(
      article.copyWith(
        content: rows.single['article_content'] as String? ?? '',
      ),
    );
    final title = rows.single['article_title'] as String?;
    if (title != null && title != article.title) {
      await renameArticle(articleId: articleId, title: title);
    }
  }

  @override
  Future<void> upsertDraft(ArticleDraft draft) async {
    if (!(_store.location?.schema.writesAllowed ?? false)) return;
    await _store.database.insert('ZephyrDraft', {
      'article_id': draft.articleId,
      'content': draft.content,
      'title': draft.title,
      'updated_at': draft.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clearDraft(String articleId) async {
    if (_store.location == null) return;
    try {
      await _store.database.delete(
        'ZephyrDraft',
        where: 'article_id = ?',
        whereArgs: [articleId],
      );
    } on Object {
      // Table may be missing on read-only / foreign libraries.
    }
  }

  @override
  Future<ArticleDraft?> getDraft(String articleId) async {
    if (_store.location == null) return null;
    try {
      final rows = await _store.database.query(
        'ZephyrDraft',
        where: 'article_id = ?',
        whereArgs: [articleId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _draftFromRow(rows.single);
    } on Object {
      return null;
    }
  }

  @override
  Future<List<ArticleDraft>> listDraftsNewerThanArticles() async {
    if (_store.location == null) return const [];
    try {
      final drafts = await _store.database.query('ZephyrDraft');
      final out = <ArticleDraft>[];
      for (final row in drafts) {
        final draft = _draftFromRow(row);
        final articles = await _store.database.query(
          'Article',
          columns: ['content', 'title', 'updateTime'],
          where: 'id = ?',
          whereArgs: [draft.articleId],
          limit: 1,
        );
        if (articles.isEmpty) {
          out.add(draft);
          continue;
        }
        final article = articles.single;
        final articleUpdated = _date(article['updateTime']! as int);
        final contentDiffers =
            (article['content'] as String? ?? '') != draft.content ||
            (article['title'] as String? ?? '') != draft.title;
        if (contentDiffers && !draft.updatedAt.isBefore(articleUpdated)) {
          out.add(draft);
        }
      }
      return out;
    } on Object {
      return const [];
    }
  }

  ArticleDraft _draftFromRow(Map<String, Object?> row) => ArticleDraft(
    articleId: row['article_id']! as String,
    content: row['content']! as String,
    title: row['title']! as String,
    updatedAt: _date(row['updated_at']! as int),
  );

  @override
  Future<List<BackupEntry>> listBackups() =>
      _store.backups.listBackups(_libraryRoot);

  @override
  Future<BackupEntry> createBackup({required BackupKind kind}) async {
    _store.ensureWritable();
    final root = _libraryRoot;
    File? snapshot;
    try {
      final label = await _backupFileLabel();
      snapshot = await _store.snapshotRoomDbToTemp();
      return await _store.backups.createPwb(
        libraryRoot: root,
        roomDb: snapshot,
        kind: kind,
        label: label,
      );
    } finally {
      final parent = snapshot?.parent;
      if (parent != null && await parent.exists()) {
        await parent.delete(recursive: true);
      }
    }
  }

  Future<BackupFileLabel> _backupFileLabel() async {
    final db = _store.database;
    final bookRows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM Folder "
      "WHERE deleted = 0 AND id != ?",
      [WritingFolder.trashId],
    );
    final articleRows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM Article WHERE deleted = 0',
    );
    final package = await PackageInfo.fromPlatform();
    final device = await resolveDeviceLabel();
    return BackupFileLabel(
      bookCount: _countOf(bookRows),
      articleCount: _countOf(articleRows),
      appVersion: package.version,
      deviceName: device,
      createdAt: DateTime.now(),
    );
  }

  static int _countOf(List<Map<String, Object?>> rows) {
    final value = rows.single['c'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  @override
  Future<void> pruneBackups({int keep = 25}) async {
    await _store.backups.pruneBackups(_libraryRoot, keep: keep);
  }

  static const _cloudLibraryIdKey = 'cloud_library_id';

  @override
  Future<QuickToolbarConfig?> readQuickToolbarConfig() async {
    final db = _store.database;
    final rows = await db.query(
      'ZephyrMeta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.quickToolbarConfig],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final raw = rows.first['value'] as String?;
      final config = _quickToolbarConfigFromMeta(raw);
      if (config != null) return config;
    }
    final legacyIds = await _readLegacyQuickToolbarFormatSelectionIds(db);
    if (legacyIds != null) {
      return QuickToolbarConfig.defaults.copyWith(
        formatSelectionIds: legacyIds,
      );
    }
    return null;
  }

  @override
  Future<void> writeQuickToolbarConfig(QuickToolbarConfig config) async {
    _store.ensureWritable();
    await _store.database.insert(
      'ZephyrMeta',
      {
        'key': ZephyrMetaKeys.quickToolbarConfig,
        'value': jsonEncode(config.normalized().toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  QuickToolbarConfig? _quickToolbarConfigFromMeta(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return QuickToolbarConfig.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<List<String>?> _readLegacyQuickToolbarFormatSelectionIds(
    Database db,
  ) async {
    final rows = await db.query(
      'ZephyrMeta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [ZephyrMetaKeys.quickToolbarFormatSelection],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded.whereType<String>().toList(growable: false);
  }

  @override
  Future<String> ensureCloudLibraryId() async {
    final db = _store.database;
    final rows = await db.query(
      'ZephyrMeta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_cloudLibraryIdKey],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final value = rows.first['value'] as String?;
      if (value != null && value.isNotEmpty) return value;
    }
    final id = _uuid.v4();
    await setCloudLibraryId(id);
    return id;
  }

  @override
  Future<bool> hasArticleContent() async {
    final db = _store.database;
    if (!await _hasTable(db, 'Article')) return false;
    final rows = await db.rawQuery(
      "SELECT 1 FROM Article WHERE deleted = 0 AND length(trim(content)) > 0 "
      'LIMIT 1',
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> setCloudLibraryId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('cloud library id must not be empty');
    }
    await _store.database.insert('ZephyrMeta', {
      'key': _cloudLibraryIdKey,
      'value': trimmed,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<LibraryMergeStats> restoreBackup({
    required BackupEntry entry,
    required RestoreMode mode,
  }) async {
    _store.ensureWritable();
    final rootPath = _store.location!.rootPath;
    // Safety net before destructive restore.
    await createBackup(kind: BackupKind.manual);
    switch (mode) {
      case RestoreMode.overwrite:
        await _restoreOverwrite(File(entry.path), rootPath);
        return LibraryMergeStats.empty;
      case RestoreMode.merge:
        return _restoreMerge(File(entry.path));
    }
  }

  Directory get _libraryRoot {
    final root = _store.location?.rootPath;
    if (root == null) {
      throw StateError('No PureWriter library is open.');
    }
    return Directory(root);
  }

  Future<void> _restoreOverwrite(File pwb, String rootPath) async {
    final room = _store.roomDbFile;
    final backups = _store.backups;
    await _store.close();
    await _deleteSqliteSidecars(room);
    await backups.restoreRoomDb(pwb: pwb, destinationRoomDb: room);
    await _store.openLibrary(rootPath, createIfMissing: false);
  }

  Future<LibraryMergeStats> _restoreMerge(File pwb) async {
    File? extracted;
    Database? backupDb;
    try {
      extracted = await _store.backups.extractRoomDbToTemp(pwb);
      backupDb = await _store.openReadOnlyDatabase(extracted);
      await _mergeTable(
        backupDb: backupDb,
        table: 'Folder',
        idColumn: 'id',
        timeColumn: 'updateTime',
      );
      await _mergeTable(
        backupDb: backupDb,
        table: 'Category',
        idColumn: 'id',
        timeColumn: 'updateTime',
      );
      final articleStats = await _mergeTable(
        backupDb: backupDb,
        table: 'Article',
        idColumn: 'id',
        timeColumn: 'updateTime',
        trackArticleStats: true,
      );
      await _mergeHistory(backupDb);
      await _mergeZephyrDrafts(backupDb);
      await _aiChat.mergeFromBackupDatabase(backupDb);
      return articleStats;
    } finally {
      await backupDb?.close();
      final parent = extracted?.parent;
      if (parent != null && await parent.exists()) {
        await parent.delete(recursive: true);
      }
    }
  }

  Future<LibraryMergeStats> _mergeTable({
    required Database backupDb,
    required String table,
    required String idColumn,
    required String timeColumn,
    bool trackArticleStats = false,
  }) async {
    final localDb = _store.database;
    if (!await _hasTable(localDb, table) || !await _hasTable(backupDb, table)) {
      return LibraryMergeStats.empty;
    }
    final remoteRows = await backupDb.query(table);
    if (remoteRows.isEmpty) return LibraryMergeStats.empty;
    final hasDeleted =
        await _hasColumn(localDb, table, 'deleted') &&
        await _hasColumn(backupDb, table, 'deleted');
    final localRows = await localDb.query(
      table,
      columns: trackArticleStats ? null : [idColumn, timeColumn],
    );
    final localById = {
      if (trackArticleStats)
        for (final row in localRows) row[idColumn]: row,
    };
    final hasHistory = trackArticleStats && await _hasHistoryTable(localDb);
    final historyKeys = <(Object?, Object?, Object?)>{
      if (hasHistory)
        for (final row in await localDb.query(
          'History',
          columns: ['article_id', 'article_content', 'article_updateTime'],
        ))
          (
            row['article_id'],
            row['article_content'],
            row['article_updateTime'],
          ),
    };
    final localTimes = <Object?, int>{
      for (final row in localRows)
        row[idColumn]: (row[timeColumn] as int?) ?? 0,
    };
    final localDeleted = <Object?, int>{
      if (trackArticleStats && hasDeleted)
        for (final row in localRows)
          row[idColumn]: (row['deleted'] as int?) ?? 0,
    };
    var added = 0;
    var updated = 0;
    var removed = 0;
    await localDb.transaction((txn) async {
      final batch = txn.batch();
      for (final remote in remoteRows) {
        final id = remote[idColumn];
        if (id == null) continue;
        final remoteTime = (remote[timeColumn] as int?) ?? 0;
        final localTime = localTimes[id];
        final local = localById[id];
        final remoteDeleted = hasDeleted
            ? ((remote['deleted'] as int?) ?? 0)
            : 0;
        if (localTime == null) {
          batch.insert(table, remote);
          if (trackArticleStats) {
            if (remoteDeleted == 1) {
              removed++;
            } else {
              added++;
            }
          }
        } else {
          if (hasHistory &&
              local != null &&
              (local['content'] != remote['content'] ||
                  local['title'] != remote['title'])) {
            final preserved = remoteTime > localTime ? local : remote;
            final key = (id, preserved['content'], preserved[timeColumn]);
            if (historyKeys.add(key)) {
              batch.insert(
                'History',
                _historySnapshot(
                  preserved,
                  DateTime.now().millisecondsSinceEpoch,
                ),
              );
            }
          }
          // Equal timestamps are ambiguous across devices: keep the local
          // article and retain the remote text in History.
          if (remoteTime <= localTime) continue;
          batch.update(table, remote, where: '$idColumn = ?', whereArgs: [id]);
          if (trackArticleStats) {
            final wasDeleted = localDeleted[id] ?? 0;
            if (remoteDeleted == 1 && wasDeleted != 1) {
              removed++;
            } else if (remoteDeleted != 1) {
              updated++;
            }
          }
        }
      }
      await batch.commit(noResult: true);
    });
    if (!trackArticleStats) return LibraryMergeStats.empty;
    return LibraryMergeStats(
      articlesAdded: added,
      articlesUpdated: updated,
      articlesRemoved: removed,
    );
  }

  Future<void> _mergeHistory(Database backupDb) async {
    final localDb = _store.database;
    if (!await _hasHistoryTable(localDb) || !await _hasHistoryTable(backupDb)) {
      return;
    }
    final remoteRows = await backupDb.query('History');
    if (remoteRows.isEmpty) return;
    final existingRows = await localDb.query(
      'History',
      columns: ['article_id', 'createTime', 'article_content'],
    );
    final existing = <String>{
      for (final row in existingRows)
        '${row['article_id']}|${row['createTime']}|${row['article_content']}',
    };
    await localDb.transaction((txn) async {
      final batch = txn.batch();
      for (final remote in remoteRows) {
        final articleId = remote['article_id'];
        final createTime = remote['createTime'];
        final content = remote['article_content'] as String? ?? '';
        if (articleId == null || createTime == null) continue;
        final key = '$articleId|$createTime|$content';
        if (existing.contains(key)) continue;
        existing.add(key);
        final copy = Map<String, Object?>.from(remote)..remove('id');
        batch.insert('History', copy);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _mergeZephyrDrafts(Database backupDb) async {
    final localDb = _store.database;
    if (!await _hasTable(localDb, 'ZephyrDraft') ||
        !await _hasTable(backupDb, 'ZephyrDraft')) {
      return;
    }
    final remoteRows = await backupDb.query('ZephyrDraft');
    if (remoteRows.isEmpty) return;
    final localRows = await localDb.query(
      'ZephyrDraft',
      columns: ['article_id', 'updated_at'],
    );
    final localTimes = <String, int>{
      for (final row in localRows)
        row['article_id']! as String: (row['updated_at'] as int?) ?? 0,
    };
    await localDb.transaction((txn) async {
      final batch = txn.batch();
      for (final remote in remoteRows) {
        final id = remote['article_id'] as String?;
        if (id == null) continue;
        final remoteTime = (remote['updated_at'] as int?) ?? 0;
        final localTime = localTimes[id];
        if (localTime == null || remoteTime >= localTime) {
          batch.insert(
            'ZephyrDraft',
            remote,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> _deleteSqliteSidecars(File room) async {
    for (final suffix in ['-journal', '-wal', '-shm']) {
      final file = File('${room.path}$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<bool> _hasTable(DatabaseExecutor database, String name) async =>
      (await database.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
        [name],
      )).isNotEmpty;

  Future<bool> _hasColumn(
    DatabaseExecutor database,
    String table,
    String column,
  ) async =>
      (await database.rawQuery('PRAGMA table_info($table)'))
          .any((row) => row['name'] == column);

  @override
  Future<List<AiChatSession>> listAiChatSessions(
    String articleId, {
    bool includeArchived = false,
  }) => _aiChat.listSessions(articleId, includeArchived: includeArchived);

  @override
  Future<AiChatSession?> loadActiveAiChatSession(String articleId) =>
      _aiChat.loadActivePersistedSession(articleId);

  @override
  Future<void> beginNewAiChatConversation(String articleId) =>
      _aiChat.beginNewConversation(articleId);

  @override
  Future<AiChatSession?> getAiChatSession(String sessionId) =>
      _aiChat.getSession(sessionId);

  @override
  Future<AiChatSession> createAiChatSession({
    required String articleId,
    String? title,
  }) => _aiChat.createSession(articleId: articleId, title: title);

  @override
  Future<void> setActiveAiChatSession({
    required String articleId,
    required String sessionId,
  }) => _aiChat.setActiveSessionId(articleId, sessionId);

  @override
  Future<void> renameAiChatSession({
    required String sessionId,
    required String title,
  }) async {
    final session = await _aiChat.getSession(sessionId);
    if (session == null) return;
    await _aiChat.updateSession(
      session.copyWith(title: title.trim(), updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> archiveAiChatSession(
    String sessionId, {
    required bool archived,
  }) => _aiChat.setArchived(sessionId, archived);

  @override
  Future<void> deleteAiChatSession(String sessionId) =>
      _aiChat.deleteSession(sessionId);

  @override
  Future<List<AiChatStoredMessage>> listAiChatMessages(String sessionId) =>
      _aiChat.listMessages(sessionId);

  @override
  Future<AiChatStoredMessage> appendAiChatMessage({
    required String sessionId,
    required AiChatMessageRole role,
    required String body,
    String thinking = '',
  }) => _aiChat.appendMessage(
    sessionId: sessionId,
    role: role,
    body: body,
    thinking: thinking,
  );

  @override
  Future<void> updateAiChatMessage({
    required String messageId,
    required String body,
    String thinking = '',
  }) => _aiChat.updateMessageBody(
    messageId: messageId,
    body: body,
    thinking: thinking,
  );

  @override
  Future<void> updateAiChatSessionSummary({
    required String sessionId,
    required String contextSummary,
  }) async {
    final session = await _aiChat.getSession(sessionId);
    if (session == null) return;
    await _aiChat.updateSession(
      session.copyWith(
        contextSummary: contextSummary,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> pruneAiChatMessagesBefore({
    required String sessionId,
    required int keepFromSortOrder,
  }) => _aiChat.deleteMessagesBeforeSortOrder(
    sessionId: sessionId,
    keepFromSortOrder: keepFromSortOrder,
  );
}
