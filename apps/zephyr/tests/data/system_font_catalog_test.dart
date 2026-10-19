import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/services/system_font_catalog.dart';

void main() {
  test('windows catalog maps msyh.ttc to 微软雅黑', () async {
    final catalog = SystemFontCatalog(
      runReg: (arguments) async {
        final key = arguments[1];
        if (key.startsWith(r'HKLM\')) {
          return '''
HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts
    Microsoft YaHei & Microsoft YaHei UI (TrueType)    REG_SZ    msyh.ttc
    Microsoft YaHei Bold & Microsoft YaHei UI Bold (TrueType)    REG_SZ    msyhbd.ttc
    Arial (TrueType)    REG_SZ    arial.ttf
''';
        }
        return '''
HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts
''';
      },
    );

    final fonts = await catalog.listFonts();
    final byFamily = {for (final font in fonts) font.family: font};

    expect(byFamily.containsKey('微软雅黑'), isTrue);
    expect(byFamily['微软雅黑']!.path.toLowerCase(), endsWith(r'\fonts\msyh.ttc'));
    expect(byFamily.containsKey('微软雅黑 Bold'), isTrue);
    expect(byFamily.containsKey('Arial'), isTrue);
    expect(byFamily.containsKey('msyh'), isFalse);
  }, skip: !Platform.isWindows);

  test('windows catalog resolves absolute user font paths', () async {
    final catalog = SystemFontCatalog(
      runReg: (arguments) async {
        if (arguments[1].startsWith(r'HKCU\')) {
          return r'''
HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
    JetBrains Mono (TrueType)    REG_SZ    C:\Users\me\AppData\Local\Microsoft\Windows\Fonts\JetBrainsMono-Regular.ttf
''';
        }
        return '''
HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts
''';
      },
    );

    final fonts = await catalog.listFonts();

    expect(fonts, hasLength(1));
    expect(fonts.single.family, 'JetBrains Mono');
    expect(
      fonts.single.path,
      r'C:\Users\me\AppData\Local\Microsoft\Windows\Fonts\JetBrainsMono-Regular.ttf',
    );
  }, skip: !Platform.isWindows);
}
