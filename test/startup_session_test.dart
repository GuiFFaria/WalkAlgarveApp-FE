import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';

final expired = 'header.${base64Url.encode(utf8.encode(jsonEncode({
      'exp': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000,
    })))}.signature';

final saved = <String, Object>{
  'auth_token': expired,
  'refresh_token': 'refresh',
  'user': '{"id": 7}',
  'cached_user_zones': '[1]',
  'cached_trails_zone_1': '[]',
  'cached_zones': '[]',
  'pending_favorites': '[{"trail_id": 1, "favorite": true, "user_id": 7}]',
};

/// Loads the saved session as the app does at startup.
Future<AuthProvider> start(
  Future<http.Response> Function(http.Request) api,
) async {
  final auth = AuthProvider();
  await http.runWithClient(auth.loadToken, () => MockClient(api));
  return auth;
}

/// What is left once the account's data is gone: the public zone list and the
/// waiting favorites, which name their account.
const signedOut = {'cached_zones', 'pending_favorites'};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(saved);
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
  });

  final unavailable = <String, Future<http.Response> Function(http.Request)>{
    'there is no connection': (_) async =>
        throw http.ClientException('offline'),
    'the server does not answer': (_) async => throw TimeoutException('slow'),
    'the server fails': (_) async => http.Response('', 500),
    'a Wi-Fi sign-in page answers': (_) async =>
        http.Response('<html>', 200),
    'the reply has no token': (_) async => http.Response('{}', 200),
  };
  unavailable.forEach((situation, api) {
    test('stays signed in when $situation', () async {
      final auth = await start(api);

      final prefs = await SharedPreferences.getInstance();
      expect(auth.isLoggedIn, isTrue);
      expect(prefs.getKeys(), saved.keys.toSet());
      expect(prefs.getString('refresh_token'), 'refresh');
    });
  });

  test('a rejected session signs out and removes the account\'s data',
      () async {
    final auth = await start((_) async => http.Response('{}', 401));

    final prefs = await SharedPreferences.getInstance();
    expect(auth.isLoggedIn, isFalse);
    expect(prefs.getKeys(), signedOut);
  });

  test('an expired session with no refresh token signs out', () async {
    SharedPreferences.setMockInitialValues(
      {...saved}..remove('refresh_token'),
    );

    final auth = await start((_) async => http.Response('{}', 200));

    final prefs = await SharedPreferences.getInstance();
    expect(auth.isLoggedIn, isFalse);
    expect(prefs.getKeys(), signedOut);
  });

  test('a renewed session replaces the access token', () async {
    final auth =
        await start((_) async => http.Response('{"access": "renewed"}', 200));

    final prefs = await SharedPreferences.getInstance();
    expect(auth.token, 'renewed');
    expect(prefs.getKeys(), saved.keys.toSet());
  });
}
