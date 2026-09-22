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
  Future<WritingLibrary> loadLibrary() async {
    final db = await _store.database;
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
      articles: articles.map(_summary).toList(growable: false),
    );
  }

  @override
  Future<WritingArticle> getArticle(String id) async {
    final rows = await (await _store.database).query(
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
    final db = await _store.database;
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
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _store.database).update(
      'Article',
      {
        'title': article.title,
        'content': article.content,
        'summary': _summaryText(article.content),
        'count': _count(article.content),
        'updateTime': now,
        'titleUpdateTime': now,
      },
      where: 'id = ?',
      whereArgs: [article.id],
    );
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
}
