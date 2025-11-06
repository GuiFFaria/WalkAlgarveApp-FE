import 'package:flutter/foundation.dart';

class TranslationHelper {
  static String getValue(
    Map item,
    String locale,
    String field, {
    String fallback = "",
  }) {
    try {
      // 1️⃣ Aceder às propriedades do item
      final properties = item['properties'] as Map?;
      if (properties == null) return fallback;

      // 2️⃣ Aceder à lista de traduções
      final translations = properties['translations'];

      if (translations is List && translations.isNotEmpty) {
        final match = translations.firstWhere(
          (t) => t['language'] == locale,
          orElse: () => null,
        );

        if (match != null &&
            match[field] != null &&
            match[field].toString().isNotEmpty) {
          debugPrint("🈯️ Found translation for '$field' in '$locale': ${match[field]}");
          return match[field].toString();
        }
      }

      // 3️⃣ Fallback → valor base sem tradução
      final baseValue = properties[field];
      if (baseValue != null && baseValue.toString().isNotEmpty) {
        debugPrint("🔡 Using base value for '$field': $baseValue");
        return baseValue.toString();
      }

      return fallback;
    } catch (e) {
      debugPrint("❌ TranslationHelper error: $e");
      return fallback;
    }
  }
}
