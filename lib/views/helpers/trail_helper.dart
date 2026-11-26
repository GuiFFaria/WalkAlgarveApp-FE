import 'package:intl/intl.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

/// Reads a trail's facts as the API returns them. Missing facts are null.
class TrailHelper {
  static String photo(Map<String, dynamic> trail) {
    // The API sends an empty address for a trail without a photo.
    return [_properties(trail)['thumbnail_url'], trail['image']]
        .map((url) => url?.toString() ?? '')
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');
  }

  static String? distance(Map<String, dynamic> trail, String locale) {
    final value = _number(_properties(trail)['distance_km'], locale);
    return value == null ? null : '$value km';
  }

  static String? duration(Map<String, dynamic> trail, String locale) {
    // The field is named in minutes but holds hours.
    final value = _number(_properties(trail)['duration_min'], locale);
    return value == null ? null : '$value h';
  }

  static String? type(Map<String, dynamic> trail) {
    final value = _text(_properties(trail)['trail_type']);
    if (value == null) return null;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static bool isCircular(Map<String, dynamic> trail) =>
      type(trail) == 'Circular';

  /// Translates the difficulties the app knows; others are shown as sent.
  static String? difficulty(
    Map<String, dynamic> trail,
    AppLocalizations translations,
  ) {
    final value = _text(_properties(trail)['difficulty']);
    return switch (value?.toLowerCase()) {
      'easy' => translations.difficulty_easy,
      'moderate' => translations.difficulty_moderate,
      'hard' => translations.difficulty_hard,
      _ => value,
    };
  }

  static bool? bikeFriendly(Map<String, dynamic> trail) {
    final value = _properties(trail)['is_bike_friendly'];
    return value is bool ? value : null;
  }

  static bool isFavorite(Map<String, dynamic> trail) {
    final value = _properties(trail)['is_favorite'];
    if (value is num) return value != 0;
    return value.toString().toLowerCase() == 'true';
  }

  static void setFavorite(Map<String, dynamic> trail, bool favorite) {
    final properties = trail['properties'] ??= <String, dynamic>{};
    properties['is_favorite'] = favorite;
  }

  static Map<dynamic, dynamic> _properties(Map<String, dynamic> trail) {
    final properties = trail['properties'];
    return properties is Map ? properties : const {};
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _number(Object? value, String locale) {
    final number = num.tryParse(value?.toString() ?? '');
    return number == null ? null : NumberFormat('0.##', locale).format(number);
  }
}
