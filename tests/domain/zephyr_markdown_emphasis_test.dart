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
