/// Reads the fields of a zone as the API returns it.
class ZoneHelper {
  /// The translated name, or the zone's own name when there is no translation.
  static String name(Map<String, dynamic> zone, String locale) {
    final translated = _translation(zone, locale, 'name');
    return translated.isNotEmpty ? translated : zone['name']?.toString() ?? '';
  }

  static String description(
    Map<String, dynamic> zone,
    String locale, {
    required String fallback,
  }) {
    final translated = _translation(zone, locale, 'description');
    return translated.isNotEmpty ? translated : fallback;
  }

  static String municipality(Map<String, dynamic> zone) {
    final value = zone['municipality'];
    final name = value is Map ? value['name'] : value;
    return name?.toString() ?? '';
  }

  static String photo(Map<String, dynamic> zone) =>
      zone['thumbnail_url']?.toString() ?? '';

  static bool isUnlocked(Map<String, dynamic> zone) =>
      zone['user_have'] == true;

  static String _translation(
    Map<String, dynamic> zone,
    String locale,
    String field,
  ) {
    final language = locale == 'pt' ? 'pt' : 'en';
    return zone['translations']?[language]?[field]?.toString() ?? '';
  }
}
