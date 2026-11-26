import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/login/login_screen.dart';
import 'package:walk_algarve_app/views/screens/profile/profile_screen.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

final en = lookupAppLocalizations(const Locale('en'));

/// A token that has not expired, so loading it needs no renewal.
final accessA = 'header.${base64Url.encode(utf8.encode(jsonEncode({
      'exp': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000,
    })))}.signature';

/// Opens a screen the way the app does, after the saved tokens are loaded.
Future<AuthProvider> open(WidgetTester tester, Widget screen) async {
  final auth = AuthProvider();
  await auth.loadToken();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(
        create: (_) => LocaleProvider()..setLocale(const Locale('en')),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> logOut(WidgetTester tester) async {
  await tester.ensureVisible(find.text(en.logout));
  await tester.pumpAndSettle();
  await tester.tap(find.text(en.logout));
  await tester.pumpAndSettle();
}

Future<void> signInAsB(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'b@example.com');
  await tester.enterText(fields.at(1), 'testpass123');
  await tester.ensureVisible(find.byType(ElevatedButton));
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

Future<T> withApi<T>(Future<T> Function() action) => http.runWithClient(
      action,
      () => MockClient((request) async => request.url.path.endsWith('/login/')
          ? http.Response(
              '{"access": "access-b", "refresh": "refresh-b", '
              '"user": {"id": 8}}',
              200,
            )
          : http.Response('{}', 200)),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': accessA,
      'refresh_token': 'refresh-a',
      'user': '{"id": 7, "username": "a", "email": "a@example.com"}',
      'cached_user_zones': '[1]',
      'cached_trails_zone_1': '[]',
      'cached_zones': '[]',
      'pending_favorites': '[{"trail_id": 1, "favorite": true, "user_id": 7}]',
    });
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
  });

  testWidgets('logging out removes the session and the account\'s saved data',
      (tester) async {
    await withApi(() async {
      final auth = await open(tester, const ProfileScreen());

      await logOut(tester);

      expect(auth.isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    final prefs = await SharedPreferences.getInstance();
    // The zone list is public, and waiting favorites name their account.
    expect(prefs.getKeys(), {'cached_zones', 'pending_favorites'});
  });

  testWidgets('the next account keeps its own refresh token', (tester) async {
    await withApi(() async {
      await open(tester, const ProfileScreen());
      await logOut(tester);

      await signInAsB(tester);
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'access-b');
    expect(prefs.getString('refresh_token'), 'refresh-b');
  });

  testWidgets('a token left by an earlier logout is replaced at sign in',
      (tester) async {
    SharedPreferences.setMockInitialValues({'refresh_token': 'refresh-a'});

    await withApi(() async {
      await open(tester, const LoginScreen());

      await signInAsB(tester);
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('refresh_token'), 'refresh-b');
  });
}
