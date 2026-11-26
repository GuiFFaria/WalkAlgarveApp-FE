import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';

// Decoded from JSON so the types match what the API responses produce.
Map<String, dynamic> trail(String properties) =>
    jsonDecode('{"properties": $properties}') as Map<String, dynamic>;

String nameOf(Map<String, dynamic> item, String locale) =>
    TranslationHelper.getValue(item, locale, 'name', fallback: 'Untitled');

void main() {
  final translated = trail('''
    {
      "name": "Base name",
      "translations": [
        {"language": "pt", "name": "Nome em portugues"},
        {"language": "en", "name": "English name"}
      ]
    }
  ''');

  test('returns the translation for the requested language', () {
    expect(nameOf(translated, 'pt'), 'Nome em portugues');
    expect(nameOf(translated, 'en'), 'English name');
  });

  test('returns the base value when the language has no translation', () {
    expect(nameOf(translated, 'fr'), 'Base name');
  });

  test('returns the base value when the translated field is empty', () {
    final item = trail(
      '{"name": "Base name", "translations": [{"language": "pt", "name": ""}]}',
    );

    expect(nameOf(item, 'pt'), 'Base name');
  });

  test('returns the base value when there are no translations', () {
    final item = trail('{"name": "Base name", "translations": []}');

    expect(nameOf(item, 'pt'), 'Base name');
  });

  test('returns the fallback when no value exists', () {
    final item = trail('{"translations": []}');

    expect(nameOf(item, 'pt'), 'Untitled');
  });

  test('returns the fallback when the item has no properties', () {
    expect(nameOf(<String, dynamic>{}, 'pt'), 'Untitled');
  });
}
