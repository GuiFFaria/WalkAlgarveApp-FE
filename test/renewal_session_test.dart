import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The mock store behind SharedPreferences, which comes with it.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';

final renewed = http.Response('{"access": "renewed-a"}', 200);
final rejected = http.Response('{}', 401);

/// Runs [action], by default a renewal, and calls [meanwhile] while the API has
/// not answered it yet. Returns what [action] returned.
Future<T> renewing<T>(
  Future<T> Function() action, {
  required http.Response reply,
  Future<void> Function()? meanwhile,
}) =>
    http.runWithClient(
      action,
      () => MockClient((_) async {
        await meanwhile?.call();
        return reply;
      }),
    );

/// Storage that calls [afterNextWrite] before a change of several keys moves on
/// to the second one.
class PausingStore extends InMemorySharedPreferencesStore {
  PausingStore(super.data) : super.withData();

  Future<void> Function()? afterNextWrite;

  @override
  Future<bool> setValue(String valueType, String key, Object value) =>
      _pause(super.setValue(valueType, key, value));

  @override
  Future<bool> remove(String key) => _pause(super.remove(key));

  Future<bool> _pause(Future<bool> write) async {
    final result = await write;
    final action = afterNextWrite;
    afterNextWrite = null;
    await action?.call();
    return result;
  }
}

/// Starts a renewal, then has its reply arrive while [change] is half saved.
Future<void> answerWhileSaving(
  AuthProvider auth,
  Future<void> Function() change,
) async {
  final store = PausingStore({
    'flutter.auth_token': 'access-token-of-a',
    'flutter.refresh_token': 'refresh-a',
  });
  SharedPreferencesStorePlatform.instance = store;
  final requested = Completer<void>();
  final reply = Completer<http.Response>();

  await http.runWithClient(() async {
    final renewal = auth.tryRefreshAccessToken();
    await requested.future;
    store.afterNextWrite = () async {
      reply.complete(renewed);
      await renewal;
    };
    await change();
  },
      () => MockClient((_) {
            requested.complete();
            return reply.future;
          }));
}

Future<void> signInAsB(AuthProvider auth) =>
    auth.setToken('access-b', refreshToken: 'refresh-b');

Future<Map<String, String?>> savedTokens() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'access': prefs.getString('auth_token'),
    'refresh': prefs.getString('refresh_token'),
  };
}

void main() {
  late AuthProvider auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'access-token-of-a',
      'refresh_token': 'refresh-a',
    });
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    auth = AuthProvider();
  });

  test('a renewal saves the new access token for the same session', () async {
    var notified = 0;
    auth.addListener(() => notified++);

    final result = await renewing(auth.tryRefreshAccessToken, reply: renewed);

    expect(result, isTrue);
    expect(auth.token, 'renewed-a');
    expect(notified, 1);
    expect(await savedTokens(), {
      'access': 'renewed-a',
      'refresh': 'refresh-a',
    });
  });

  test('a renewal that answers after logout leaves the app signed out',
      () async {
    final result = await renewing(
      auth.tryRefreshAccessToken,
      reply: renewed,
      meanwhile: () => auth.logout(),
    );

    expect(result, isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(await savedTokens(), {'access': null, 'refresh': null});
  });

  test('a renewal that answers after another sign in is discarded', () async {
    final result = await renewing(
      auth.tryRefreshAccessToken,
      reply: renewed,
      meanwhile: () => signInAsB(auth),
    );

    expect(result, isFalse);
    expect(auth.token, 'access-b');
    expect(await savedTokens(), {
      'access': 'access-b',
      'refresh': 'refresh-b',
    });
  });

  test('a renewal that answers during a logout leaves no token behind',
      () async {
    await answerWhileSaving(auth, auth.logout);

    expect(auth.isLoggedIn, isFalse);
    expect(await savedTokens(), {'access': null, 'refresh': null});
  });

  test('a renewal that answers during a sign in keeps the new tokens',
      () async {
    await answerWhileSaving(auth, () => signInAsB(auth));

    expect(auth.token, 'access-b');
    expect(await savedTokens(), {
      'access': 'access-b',
      'refresh': 'refresh-b',
    });
  });

  test('a rejection of an earlier session does not sign out the new one',
      () async {
    // Loading at startup is the renewal that signs out on a rejection.
    await renewing(
      auth.loadToken,
      reply: rejected,
      meanwhile: () => signInAsB(auth),
    );

    expect(auth.token, 'access-b');
    expect(await savedTokens(), {
      'access': 'access-b',
      'refresh': 'refresh-b',
    });
  });
}
