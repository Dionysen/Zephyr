import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:zephyr/ui/core/zephyr_markdown_body.dart';

void main() {
  test('prepareZephyrMarkdownForParse enables bold around CJK quotes', () {
    const raw = '这是**「重要」**的内容';
    final prepared = prepareZephyrMarkdownForParse(raw);
    expect(prepared, isNot(raw));

    final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final nodes = doc.parseLines(prepared.split('\n'));
    expect(nodes, hasLength(1));
    final p = nodes.single as md.Element;
    expect(p.tag, 'p');
    final strong = p.children!
        .whereType<md.Element>()
        .where((e) => e.tag == 'strong')
        .toList();
    expect(strong, hasLength(1));
    expect(strong.single.textContent, contains('重要'));
  });

  test('streaming split keeps the open line out of committed markdown', () {
    expect(splitStreamingMarkdown('第一行\n第二'), (committed: '第一行', tail: '第二'));
    expect(splitStreamingMarkdown('只有一行'), (committed: '', tail: '只有一行'));
    expect(splitStreamingMarkdown('段落\n'), (committed: '段落', tail: ''));
  });

  test('standalone bold quoted sentence still parses', () {
    final prepared = prepareZephyrMarkdownForParse('**「你好」**');
    final doc = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored);
    final p = doc.parseLines(prepared.split('\n')).single as md.Element;
    expect(
      p.children!.whereType<md.Element>().any((e) => e.tag == 'strong'),
      isTrue,
    );
  });
}
