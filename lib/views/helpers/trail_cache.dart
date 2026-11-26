import 'package:shared_preferences/shared_preferences.dart';

/// The trail lists saved for offline use, one per zone.
class TrailCache {
  static const _prefix = 'cached_trails_zone_';

  static String key(Object? zoneId) => '$_prefix$zoneId';

  /// The lists hold the account's favorites, so they leave with it.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) await prefs.remove(key);
    }
  }
}
