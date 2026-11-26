import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/helpers/favorites_store.dart';

void connectivity(String result) {
  TestWidgetsFlutterBinding.ensureInitialized()
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => [result],
      );
}

void signIn(int userId, {List<Map<String, dynamic>> waiting = const []}) {
  SharedPreferences.setMockInitialValues({
    'auth_token': 'token',
    'user': jsonEncode({'id': userId}),
    if (waiting.isNotEmpty) 'pending_favorites': jsonEncode(waiting),
  });
}

Future<List<dynamic>> queue() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString('pending_favorites') ?? '[]');
}

http.Response reply(bool favorite) => http.Response(
      jsonEncode({'is_favorite': favorite}),
      favorite ? 201 : 200,
    );

/// A fake API that flips the favorite on each request, as the real one does.
class Api {
  final favorites = <int>{};
  final requests = <http.Request>[];

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final id = jsonDecode(request.body)['trail_id'] as int;
    final added = !favorites.remove(id);
    if (added) favorites.add(id);
    return reply(added);
  }
}

Future<T> against<T>(
  Future<http.Response> Function(http.Request) api,
  Future<T> Function() action,
) =>
    http.runWithClient(action, () => MockClient(api));

void main() {
  late FavoritesStore store;

  setUp(() {
    signIn(7);
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    connectivity('wifi');
    store = FavoritesStore(refreshToken: () async => false);
  });

  test('a confirmed change leaves nothing waiting', () async {
    final api = Api();

    final outcome =
        await against(api.handle, () => store.setFavorite(1, true));

    expect(outcome, FavoriteOutcome.saved);
    expect(api.favorites, {1});
    expect(await queue(), isEmpty);
    expect(api.requests.single.headers['Authorization'], 'Bearer token');
  });

  test('offline, only the latest choice for a trail waits', () async {
    connectivity('none');
    final api = Api();

    await against(api.handle, () async {
      await store.setFavorite(1, true);
      expect(await store.setFavorite(1, false), FavoriteOutcome.queued);
    });

    expect(api.requests, isEmpty);
    expect(await store.pending(), {1: false});
  });

  test('waiting changes are sent after reconnecting', () async {
    connectivity('none');
    final api = Api();

    await against(api.handle, () async {
      await store.setFavorite(1, true);
      await store.setFavorite(2, true);
      connectivity('wifi');
      await store.sync();
    });

    expect(api.favorites, {1, 2});
    expect(await queue(), isEmpty);
  });

  test('a reply that disagrees is corrected with a second request', () async {
    // Already a favorite on the server, so the first request removes it.
    final api = Api()..favorites.add(1);

    final outcome =
        await against(api.handle, () => store.setFavorite(1, true));

    expect(outcome, FavoriteOutcome.saved);
    expect(api.favorites, {1});
    expect(api.requests, hasLength(2));
  });

  final failures = <String, Future<http.Response> Function(http.Request)>{
    'a lost connection': (_) async => throw http.ClientException('lost'),
    'a server error': (_) async => http.Response('', 500),
    'a busy server': (_) async => http.Response('', 429),
    'a Wi-Fi sign-in page': (_) async => http.Response('<html>', 200),
  };
  failures.forEach((name, api) {
    test('$name keeps the change waiting', () async {
      final outcome = await against(api, () => store.setFavorite(1, true));

      expect(outcome, FavoriteOutcome.queued);
      expect(await store.pending(), {1: true});
    });
  });

  test('sync stops at the first change it cannot send', () async {
    signIn(7, waiting: [
      {'trail_id': 1, 'favorite': true, 'user_id': 7},
      {'trail_id': 2, 'favorite': true, 'user_id': 7},
    ]);
    var requests = 0;

    await against((_) async {
      requests++;
      return http.Response('', 503);
    }, store.sync);

    expect(requests, 1);
    expect(await queue(), hasLength(2));
  });

  test('a refused change is dropped', () async {
    final outcome = await against(
      (_) async => http.Response('', 404),
      () => store.setFavorite(1, true),
    );

    expect(outcome, FavoriteOutcome.rejected);
    expect(await queue(), isEmpty);
  });

  test('an expired token is renewed and the change sent again', () async {
    final api = Api();
    store = FavoritesStore(refreshToken: () async {
      final prefs = await SharedPreferences.getInstance();
      return prefs.setString('auth_token', 'renewed');
    });

    final outcome = await against(
      (request) async =>
          request.headers['Authorization'] == 'Bearer renewed'
              ? api.handle(request)
              : http.Response('', 401),
      () => store.setFavorite(1, true),
    );

    expect(outcome, FavoriteOutcome.saved);
    expect(api.favorites, {1});
  });

  test('without a new token the change waits for the next sign in', () async {
    final outcome = await against(
      (_) async => http.Response('', 401),
      () => store.setFavorite(1, true),
    );

    expect(outcome, FavoriteOutcome.signInNeeded);
    expect(await store.pending(), {1: true});
  });

  test('another account\'s changes are neither shown nor sent', () async {
    signIn(8, waiting: [
      {'trail_id': 1, 'favorite': true, 'user_id': 7},
    ]);
    final api = Api();

    expect(await store.pending(), isEmpty);
    await against(api.handle, () async {
      await store.sync();
      await store.setFavorite(1, true);
    });

    expect(api.requests, hasLength(1));
    expect(await queue(), [
      {'trail_id': 1, 'favorite': true, 'user_id': 7},
    ]);
  });

  test('changes queued by the earlier version are sent once each', () async {
    signIn(7, waiting: [
      for (var i = 0; i < 3; i++) {'trail_id': 1, 'timestamp': '$i'},
    ]);
    final api = Api();

    await against(api.handle, store.sync);

    expect(api.requests, hasLength(3));
    expect(api.favorites, {1});
    expect(await queue(), isEmpty);
  });

  test('a tap during a request waits and has the last word', () async {
    final api = Api();
    final release = Completer<void>();

    await against((request) async {
      await release.future;
      return api.handle(request);
    }, () async {
      final first = store.setFavorite(1, true);
      await pumpEventQueue();
      final second = store.setFavorite(1, false);
      await pumpEventQueue();
      release.complete();
      await Future.wait([first, second]);
    });

    expect(api.favorites, isEmpty);
    expect(api.requests, hasLength(2));
    expect(await queue(), isEmpty);
  });
}
