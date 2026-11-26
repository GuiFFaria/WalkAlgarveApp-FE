import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/helpers/connectivity_helper.dart';
import 'package:walk_algarve_app/views/helpers/debug_helper.dart';

enum FavoriteOutcome { saved, queued, signInNeeded, rejected }

/// Sends favorite changes to the API, keeping each one until it is confirmed.
class FavoritesStore {
  FavoritesStore({required this.refreshToken});

  final Future<bool> Function() refreshToken;

  static const _key = 'pending_favorites';
  static const _timeout = Duration(seconds: 15);

  /// Shared by every instance: two requests at once would undo each other.
  static Future<void>? _sending;

  Future<FavoriteOutcome> setFavorite(Object trailId, bool favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _userId(prefs);
    final queue = _read(prefs)
      ..removeWhere((c) => c['trail_id'] == trailId && _isFrom(c, userId))
      ..add({'trail_id': trailId, 'favorite': favorite, 'user_id': userId});
    await _write(prefs, queue);

    if (!await ConnectivityHelper.hasConnection()) {
      return FavoriteOutcome.queued;
    }
    return _oneAtATime(() => _send(trailId));
  }

  /// Sends the signed-in user's waiting changes, stopping if they can't go out.
  Future<void> sync() async {
    for (final trailId in (await _mine()).map((c) => c['trail_id']).toSet()) {
      final outcome = await _oneAtATime(() => _send(trailId as Object));
      if (outcome == FavoriteOutcome.queued ||
          outcome == FavoriteOutcome.signInNeeded) {
        return;
      }
    }
  }

  /// The state wanted for each trail whose change is still waiting.
  Future<Map<Object?, bool>> pending() async => {
        for (final change in await _mine())
          if (change['favorite'] is bool)
            change['trail_id']: change['favorite'] as bool,
      };

  Future<FavoriteOutcome> _send(Object trailId) async {
    // The API only flips a favorite, so a second request may be needed.
    for (var attempt = 0; attempt < 2; attempt++) {
      final prefs = await SharedPreferences.getInstance();
      final userId = _userId(prefs);
      bool isThisChange(Map<String, dynamic> c) =>
          c['trail_id'] == trailId && _isFrom(c, userId);

      if (!_read(prefs).any(isThisChange)) return FavoriteOutcome.saved;

      final http.Response response;
      try {
        response = await _post(trailId);
      } catch (e) {
        DebugLogger.error('FavoritesStore', 'Send failed', e);
        return FavoriteOutcome.queued;
      }

      final status = response.statusCode;
      if (status == 401 || status == 403) return FavoriteOutcome.signInNeeded;
      if (status >= 500 || status == 408 || status == 429) {
        return FavoriteOutcome.queued;
      }
      if (status >= 400) {
        DebugLogger.error('FavoritesStore', 'Change refused: $status');
        await _write(prefs, _read(prefs)..removeWhere(isThisChange));
        return FavoriteOutcome.rejected;
      }

      // Anything else, such as a Wi-Fi sign-in page, confirms nothing.
      final favorite = _favoriteIn(response);
      if (favorite == null) return FavoriteOutcome.queued;

      // Read again: the heart may have been tapped while the request was out.
      final queue = _read(prefs);
      final index = queue.indexWhere(isThisChange);
      if (index < 0) return FavoriteOutcome.saved;

      final wanted = queue[index]['favorite'];
      // Changes queued by earlier versions say only "flip", once each.
      if (wanted == null || wanted == favorite) {
        await _write(prefs, queue..removeAt(index));
        if (!queue.any(isThisChange)) return FavoriteOutcome.saved;
        if (wanted == null) attempt--;
      }
    }
    return FavoriteOutcome.queued;
  }

  /// Retries once with a renewed token, since the old one lasts an hour.
  Future<http.Response> _post(Object trailId) async {
    Future<http.Response> attempt() async {
      final prefs = await SharedPreferences.getInstance();
      final token =
          prefs.getString('auth_token')?.replaceAll('"', '').trim() ?? '';
      return http
          .post(
            Uri.parse('${dotenv.env['API_BASE_URL']!}/trails/'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'trail_id': trailId}),
          )
          .timeout(_timeout);
    }

    final response = await attempt();
    if (response.statusCode == 401 && await refreshToken()) {
      return attempt();
    }
    return response;
  }

  Future<T> _oneAtATime<T>(Future<T> Function() action) async {
    while (_sending != null) {
      await _sending;
    }
    final done = Completer<void>();
    _sending = done.future;
    try {
      return await action();
    } finally {
      _sending = null;
      done.complete();
    }
  }

  Future<List<Map<String, dynamic>>> _mine() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _userId(prefs);
    return _read(prefs).where((c) => _isFrom(c, userId)).toList();
  }

  /// Changes queued by earlier versions name no account.
  static bool _isFrom(Map<String, dynamic> change, Object? userId) =>
      change['user_id'] == null || change['user_id'] == userId;

  static Object? _userId(SharedPreferences prefs) {
    final user = prefs.getString('user');
    return user == null ? null : jsonDecode(user)['id'];
  }

  static bool? _favoriteIn(http.Response response) {
    try {
      final favorite = jsonDecode(response.body)['is_favorite'];
      return favorite is bool ? favorite : null;
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> _read(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return saved == null
        ? []
        : List<Map<String, dynamic>>.from(jsonDecode(saved));
  }

  static Future<void> _write(
    SharedPreferences prefs,
    List<Map<String, dynamic>> queue,
  ) =>
      prefs.setString(_key, jsonEncode(queue));
}
