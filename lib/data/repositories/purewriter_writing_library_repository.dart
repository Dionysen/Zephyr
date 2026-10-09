import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/purewriter_models.dart';
import '../../domain/repositories/writing_library_repository.dart';
import '../services/purewriter_database.dart';

class PureWriterWritingLibraryRepository implements WritingLibraryRepository {
  PureWriterWritingLibraryRepository(this._store, {Uuid? uuid})
    : _uuid = uuid ?? Uuid();
  final PureWriterDatabase _store;
  final Uuid _uuid;

  @override
  LibraryLocation? get location => _store.location;

  @override
  Future<LibraryLocation> openLibrary(String rootPath) =>
      _store.openLibrary(rootPath, createIfMissing: true);

  @override
  Future<LibraryLocation> openDefaultLibrary() =>
      _store.openDefaultLibrary();

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
    final updated = await _store.database.update(
      'Article',
      {
        'title': trimmed,
        'titleUpdateTime': now,
        'updateTime': now,
      },
      where: 'id = ? AND deleted = 0',
      whereArgs: [articleId],
    );
    if (updated == 0) {
      throw StateError('PureWriter article not found: $articleId');
    }
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
          'summary': _summaryText(article.content),
          'count': _count(article.content),
          'updateTime': now,
        },
        where: 'id = ?',
        whereArgs: [article.id],
      );
    });
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
  String _summaryText(String content) => content
      .replaceAll(RegExp(r'[\r\n]+'), ' ')
      .trim()
      .runes
      .take(200)
      .map(String.fromCharCode)
      .join();

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
      {
        'name': trimmed,
        'updateTime': now,
      },
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
              columns: ['createTime', 'article_content'],
              where: 'article_id = ?',
              whereArgs: [articleId],
              orderBy: 'createTime DESC',
            ))
            .map(
              (row) => ArticleHistory(
                createdAt: _date(row['createTime']! as int),
                content: row['article_content'] as String? ?? '',
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
}
