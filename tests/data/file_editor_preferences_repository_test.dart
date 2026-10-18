import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/data/repositories/file_editor_preferences_repository.dart';
import 'package:zephyr/data/services/editor_preferences_file_storage.dart';
import 'package:zephyr/domain/models/editor_preferences.dart';
import 'package:zephyr/domain/models/zephyr_bundled_fonts.dart';

void main() {
  late Directory directory;
  late EditorPreferencesFileStorage storage;
  late FileEditorPreferencesRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'zephyr-editor-preferences-',
    );
    addTearDown(() => directory.delete(recursive: true));
    storage = EditorPreferencesFileStorage(
      directoryProvider: () async => directory,
    );
    repository = FileEditorPreferencesRepository(storage);
  });

  test('missing preferences load editor defaults', () async {
    final actual = await repository.load();
    expect(actual.fontFamily, EditorPreferences.defaults.fontFamily);
    expect(actual.fontSize, EditorPreferences.defaults.fontSize);
    expect(actual.titleCentered, isTrue);
    expect(actual.typewriterMode, isFalse);
  });

  test('all editor preferences survive a file round trip', () async {
    final expected = EditorPreferences.defaults.copyWith(
      fontFamily: 'Imported',
      fontPath: '/fonts/imported.ttf',
      fontSize: 19,
      lineHeight: 1.4,
      paragraphSpacing: 0.8,
      firstLineIndent: 3,
      marginLeft: 10,
      marginRight: 12,
      editorWidth: 800,
      titleFontSize: 30,
      titleCentered: false,
      typewriterMode: true,
      jumpToEndOnScrollDown: true,
    );
    await repository.save(expected);

    final actual = await repository.load();
    expect(actual.fontFamily, expected.fontFamily);
    expect(actual.fontPath, expected.fontPath);
    expect(actual.fontSize, expected.fontSize);
    expect(actual.lineHeight, expected.lineHeight);
    expect(actual.paragraphSpacing, expected.paragraphSpacing);
    expect(actual.firstLineIndent, expected.firstLineIndent);
    expect(actual.marginLeft, expected.marginLeft);
    expect(actual.marginRight, expected.marginRight);
    expect(actual.editorWidth, expected.editorWidth);
    expect(actual.titleFontSize, expected.titleFontSize);
    expect(actual.titleCentered, expected.titleCentered);
    expect(actual.typewriterMode, expected.typewriterMode);
    expect(actual.jumpToEndOnScrollDown, expected.jumpToEndOnScrollDown);
  });

  test(
    'legacy pixel paragraph spacing is converted using saved font size',
    () async {
      await storage.write({
        'fontSize': 20,
        'lineHeight': 1.6,
        'paragraphSpacing': 10,
        'firstLineIndent': 2,
      });

      final actual = await repository.load();
      expect(actual.paragraphSpacing, 0.5);
      expect(actual.fontFamily, ZephyrBundledFonts.wenkaiLite);
      expect(actual.marginLeft, EditorPreferences.defaults.marginLeft);
      expect(actual.titleCentered, EditorPreferences.defaults.titleCentered);
    },
  );

  test(
    'custom font path without a family stays unresolved until font loading',
    () async {
      await storage.write({
        'fontPath': '/fonts/custom.ttf',
        'fontSize': 16,
        'lineHeight': 1.5,
        'paragraphSpacing': 0.5,
        'firstLineIndent': 2,
      });

      final actual = await repository.load();
      expect(actual.fontPath, '/fonts/custom.ttf');
      expect(actual.fontFamily, isNull);
    },
  );

  test('invalid stored required values fail with a format error', () async {
    await storage.write({
      'fontSize': 'large',
      'lineHeight': 1.5,
      'paragraphSpacing': 0.5,
      'firstLineIndent': 2,
    });

    await expectLater(repository.load(), throwsFormatException);
  });
}
