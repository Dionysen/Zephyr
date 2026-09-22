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
      _store.openLibrary(rootPath);

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
      updatedAt: _date(row['updateTime']! as int),
    );
  }

  @override
  Future<WritingArticle> createArticle({required String folderId}) async {
    _store.ensureWritable();
    final db = _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final rankRows = await db.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Article WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    final rank = (rankRows.single['value']! as int) + 1;
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
      'categoryId': null,
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
      'orderKey': rank.toString().padLeft(12, '0'),
      'structureUpdateTime': now,
    });
    return getArticle(id);
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
      await transaction.insert('History', _historySnapshot(original, now));
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
    updatedAt: _date(row['updateTime']! as int),
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
  }) async {
    _store.ensureWritable();
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4().replaceAll('-', '').substring(0, 24);
    final result = await _store.database.rawQuery(
      'SELECT COALESCE(MAX(rank), 0) AS value FROM Category WHERE folderId = ? AND deleted = 0',
      [folderId],
    );
    final rank = (result.single['value']! as int) + 1;
    await _store.database.insert('Category', {
      'id': id,
      'folderId': folderId,
      'name': name,
      'createdTime': now,
      'collapsed': 0,
      'rank': rank,
      'rankUpdateTime': now,
      'folderIdUpdateTime': now,
      'updateTime': now,
      'deleted': 0,
      'deletedTime': 0,
      'orderKey': rank.toString().padLeft(12, '0'),
      'structureUpdateTime': now,
    });
    return WritingCategory(
      id: id,
      folderId: folderId,
      name: name,
      rank: rank,
      collapsed: false,
    );
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
      (await _store.database.query(
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
