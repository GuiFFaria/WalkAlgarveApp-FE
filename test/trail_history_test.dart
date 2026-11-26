import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/screens/trail_map/trail_history.dart';

final endedAt = DateTime(2026, 7, 1, 12, 30);

String token(String name, {required Duration expiresIn}) {
  final expiry = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(utf8.encode('{"exp": $expiry}'));
  return '$name.$payload.signature';
}

/// Runs one walk against a fake API and returns what it received.
Future<List<http.Request>> walk(
  Future<http.Response> Function(http.Request) api, {
  AuthProvider? auth,
}) async {
  final requests = <http.Request>[];
  await http.runWithClient(() async {
    final history = TrailHistory(
      refreshToken: (auth ?? AuthProvider()).tryRefreshAccessToken,
    )..start(6);
    await history.finish(
      endedAt: endedAt,
      durationMin: 90,
      distanceKm: 5.12345,
      visitedPoiIds: [11, 12],
      rating: 4,
      notes: 'Great',
    );
  }, () => MockClient((request) {
        requests.add(request);
        return api(request);
      }));
  return requests;
}

http.Response saved(http.Request request) =>
    http.Response('{"id": 31}', request.method == 'POST' ? 201 : 200);

String describe(http.Request r) => '${r.method} ${r.url.path}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'old',
      'refresh_token': 'refresh',
      'user': '{"id": 7}',
    });
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
  });

  test('sends the walk details, with the end time in UTC', () async {
    final requests = await walk((r) async => saved(r));

    expect(jsonDecode(requests.last.body), {
      'ended_at': endedAt.toUtc().toIso8601String(),
      'duration_actual_min': 90,
      'distance_actual_km': 5.123,
      'pois_visited': [11, 12],
      'completed': true,
      'rating': 4,
      'notes': 'Great',
    });
    expect(jsonDecode(requests.last.body)['ended_at'], endsWith('Z'));
    expect(requests.last.headers['Authorization'], 'Bearer old');
  });

  // The provider has not loaded any token, as right after signing in.
  test('renews an expired session and retries once', () async {
    final requests = await walk((request) async {
      if (request.url.path.endsWith('/token/refresh/')) {
        return http.Response('{"access": "new"}', 200);
      }
      final expired = request.method == 'PATCH' &&
          request.headers['Authorization'] == 'Bearer old';
      return expired ? http.Response('{}', 401) : saved(request);
    });

    expect(requests.map(describe), [
      'POST /api/users/7/history/',
      'PATCH /api/users/7/history/31/',
      'POST /api/auth/token/refresh/',
      'PATCH /api/users/7/history/31/',
    ]);
    expect(requests.last.headers['Authorization'], 'Bearer new');
  });

  test('stays signed in when the session cannot be renewed offline', () async {
    final requests = await walk((request) async {
      if (request.url.path.endsWith('/token/refresh/')) {
        throw http.ClientException('offline');
      }
      return request.method == 'PATCH'
          ? http.Response('{}', 401)
          : saved(request);
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'old');
    expect(prefs.getString('refresh_token'), 'refresh');
    expect(requests.where((r) => r.method == 'PATCH'), hasLength(1));
  });

  test('does not try to finish a walk that was never recorded', () async {
    final requests = await walk((_) async => http.Response('{}', 400));

    expect(requests.map(describe), ['POST /api/users/7/history/']);
  });

  test('survives a lost connection', () async {
    final requests =
        await walk((_) async => throw http.ClientException('offline'));

    expect(requests, hasLength(1));
  });

  test('still signs out at launch when an expired session is rejected',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': token('old', expiresIn: const Duration(hours: -1)),
      'refresh_token': 'refresh',
    });
    final auth = AuthProvider();

    await http.runWithClient(
      auth.loadToken,
      () => MockClient((_) async => http.Response('{}', 401)),
    );

    expect(auth.isLoggedIn, isFalse);
  });
}
