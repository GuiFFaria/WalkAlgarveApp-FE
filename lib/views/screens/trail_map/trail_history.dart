import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/helpers/debug_helper.dart';

/// Saves one walk to the user's trail history.
class TrailHistory {
  TrailHistory({required this.refreshToken});

  final Future<bool> Function() refreshToken;

  static const _timeout = Duration(seconds: 15);

  Future<Uri?>? _record;

  /// Not awaited by callers, so a slow connection never delays the walk.
  void start(Object? trailId) => _record = _create(trailId);

  Future<void> finish({
    required DateTime endedAt,
    required int? durationMin,
    required double distanceKm,
    required Iterable<Object?> visitedPoiIds,
    int? rating,
    String notes = '',
  }) async {
    final record = await _record;
    if (record == null) {
      DebugLogger.warn('TrailHistory', 'No history record to finish');
      return;
    }

    try {
      final response = await _send(
        (headers) => http.patch(
          record,
          headers: headers,
          body: jsonEncode({
            // Without the UTC marker the API would read local time as UTC.
            'ended_at': endedAt.toUtc().toIso8601String(),
            'duration_actual_min': durationMin,
            'distance_actual_km': double.parse(distanceKm.toStringAsFixed(3)),
            'pois_visited': visitedPoiIds.toList(),
            'completed': true,
            if (rating != null) 'rating': rating,
            if (notes.isNotEmpty) 'notes': notes,
          }),
        ),
      );

      if (response.statusCode != 200) {
        DebugLogger.error(
            'TrailHistory', 'Finish failed: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('TrailHistory', 'Finish failed', e);
    }
  }

  Future<Uri?> _create(Object? trailId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString('user');
      final userId = user == null ? null : jsonDecode(user)['id'];
      if (userId == null || trailId == null) {
        DebugLogger.warn('TrailHistory', 'Missing user or trail id');
        return null;
      }

      final url =
          Uri.parse('${dotenv.env['API_BASE_URL']!}/users/$userId/history/');
      final response = await _send(
        (headers) => http.post(
          url,
          headers: headers,
          body: jsonEncode({'trail': trailId}),
        ),
      );

      if (response.statusCode != 201) {
        DebugLogger.error(
            'TrailHistory', 'Start failed: ${response.statusCode}');
        return null;
      }
      return url.resolve('${jsonDecode(response.body)['id']}/');
    } catch (e) {
      DebugLogger.error('TrailHistory', 'Start failed', e);
      return null;
    }
  }

  /// Retries once with a renewed token, since a walk can outlast the token.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    Future<http.Response> attempt() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token')?.trim();
      return request({
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      }).timeout(_timeout);
    }

    final response = await attempt();
    if (response.statusCode == 401 && await refreshToken()) {
      return attempt();
    }
    return response;
  }
}
