import 'dart:async';
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
import 'package:walk_algarve_app/views/components/offline_banner/offline_banner_widget.dart';
import 'package:walk_algarve_app/views/components/zone_card/zone_card_widget.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/zone_details/zone_details_screen.dart';
import 'package:walk_algarve_app/views/screens/zones_list/zones_list_screen.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

final en = lookupAppLocalizations(const Locale('en'));

Map<String, dynamic> zone(int id, String name, String municipality) => {
      'id': id,
      'name': name,
      'thumbnail_url': '',
      'municipality': {'id': id, 'name': municipality},
      'translations': {
        'en': {'name': name, 'description': 'About $name'},
      },
    };

final ludo = zone(1, 'Ludo', 'Faro');
final benagil = zone(2, 'Benagil', 'Lagoa');

/// A token as the app reads it: only the expiry matters.
String token(Duration expiresIn) {
  final expiry = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url.encode(utf8.encode('{"exp": $expiry}'));
  return 'header.$payload.signature';
}

final valid = token(const Duration(hours: 1));
final expired = token(const Duration(hours: -1));

/// The API: every zone, and the ids of the ones the user owns.
MockClient api(List<Map<String, dynamic>> zones, List<int> owned) =>
    MockClient((request) async => http.Response(
          jsonEncode(request.url.path.endsWith('/user/zones/')
              ? {'zones_owned': owned}
              : zones),
          200,
        ));

void connectivity(String result) {
  TestWidgetsFlutterBinding.ensureInitialized()
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => [result],
      );
}

Widget app(Widget screen) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
    );

Future<void> show(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(app(screen));
  await tester.pumpAndSettle();
}

void tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openZones(
  WidgetTester tester,
  List<Map<String, dynamic>> zones, {
  List<int> owned = const [],
  required Future<void> Function() then,
}) async {
  tallScreen(tester);
  await http.runWithClient(() async {
    await show(tester, const ZonesListScreen());
    await then();
  }, () => api(zones, owned));
}

/// Opens the list against an API that, like `/user/zones/`, answers 401 to any
/// token but [accepted]. Returns the requests it received.
Future<List<http.Request>> openSignedIn(
  WidgetTester tester, {
  required String accepted,
  List<int> owned = const [],
  Future<http.Response> Function()? renewal,
  int userZonesStatus = 200,
}) async {
  final requests = <http.Request>[];
  tallScreen(tester);

  await http.runWithClient(
    () => show(tester, const ZonesListScreen()),
    () => MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/auth/token/refresh/')) {
        return renewal!();
      }
      if (!request.url.path.endsWith('/user/zones/')) {
        return http.Response(jsonEncode([ludo, benagil]), 200);
      }
      if (request.headers['Authorization'] != 'Bearer $accepted') {
        return http.Response('{"code": "token_not_valid"}', 401);
      }
      return http.Response(
        jsonEncode({'zones_owned': owned}),
        userZonesStatus,
      );
    }),
  );
  return requests;
}

Iterable<String> paths(List<http.Request> requests) =>
    requests.map((request) => request.url.path);

void expectOwned(WidgetTester tester, String name) {
  expect(find.text(en.your_zones), findsOneWidget);
  expect(top(tester, name), lessThan(top(tester, en.other_zones)));
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text).first).dy;

Future<void> filterBy(WidgetTester tester, String option) async {
  await tester.tap(find.byTooltip(en.select_municipality));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, option));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': valid});
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    connectivity('wifi');
  });

  testWidgets('owned zones come first, under their own heading',
      (tester) async {
    await openZones(tester, [ludo, benagil], owned: [2], then: () async {
      expect(top(tester, en.your_zones), lessThan(top(tester, 'Benagil')));
      expect(top(tester, 'Benagil'), lessThan(top(tester, en.other_zones)));
      expect(top(tester, en.other_zones), lessThan(top(tester, 'Ludo')));
      expect(find.text(en.zone_unlocked), findsOneWidget);
      expect(find.text(en.zone_locked), findsOneWidget);
      expect(find.byType(OfflineBannerWidget), findsNothing);
    });
  });

  testWidgets('a group without zones has no heading', (tester) async {
    await openZones(tester, [ludo], then: () async {
      expect(find.text(en.your_zones), findsNothing);
      expect(find.text(en.other_zones), findsOneWidget);
    });
  });

  testWidgets('the municipality filter narrows the list and can be cleared',
      (tester) async {
    await openZones(tester, [ludo, benagil], then: () async {
      await filterBy(tester, 'Lagoa');
      expect(find.byType(ZoneCardWidget), findsOneWidget);
      expect(find.text('Benagil'), findsOneWidget);

      await tester.tap(find.byTooltip(en.select_municipality));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Lagoa'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(en.close));
      await tester.pumpAndSettle();
      expect(find.byType(ZoneCardWidget), findsOneWidget);

      await filterBy(tester, en.show_all);
      expect(find.byType(ZoneCardWidget), findsNWidgets(2));
    });
  });

  testWidgets('pull to refresh keeps the filter', (tester) async {
    var requests = 0;
    final server = api([ludo, benagil], []);
    tallScreen(tester);

    await http.runWithClient(() async {
      await show(tester, const ZonesListScreen());
      await filterBy(tester, 'Lagoa');
      final before = requests;

      await tester.fling(find.byType(ListView), const Offset(0, 600), 1000);
      await tester.pumpAndSettle();

      expect(requests, greaterThan(before));
      expect(find.byType(ZoneCardWidget), findsOneWidget);
      expect(find.text('Benagil'), findsOneWidget);
    },
        () => MockClient((request) async {
              requests++;
              return http.Response.fromStream(await server.send(
                http.Request(request.method, request.url),
              ));
            }));
  });

  testWidgets('saved zones are shown offline, with a banner', (tester) async {
    connectivity('none');
    SharedPreferences.setMockInitialValues({
      'cached_zones': jsonEncode([ludo]),
      'cached_user_zones': '[1]',
    });

    await openZones(tester, [], then: () async {
      expect(find.text(en.offline_zones), findsOneWidget);
      expect(find.text('Ludo'), findsOneWidget);
      expect(find.text(en.your_zones), findsOneWidget);
    });
  });

  testWidgets('an empty list says there are no zones', (tester) async {
    await openZones(tester, [], then: () async {
      expect(find.text(en.no_zones_available), findsOneWidget);
    });
  });

  testWidgets('a zone without a translation shows its own name',
      (tester) async {
    final untranslated = {...ludo, 'translations': <String, dynamic>{}};

    await openZones(tester, [untranslated], then: () async {
      expect(find.text('Ludo'), findsOneWidget);
    });
  });

  testWidgets('the placeholder shows a lock only on a locked zone',
      (tester) async {
    await openZones(tester, [ludo, benagil], owned: [2], then: () async {
      Finder inCard(String name, IconData icon) => find.descendant(
            of: find.widgetWithText(ZoneCardWidget, name),
            matching: find.byIcon(icon),
          );

      expect(inCard('Benagil', Icons.image_outlined), findsOneWidget);
      // The placeholder and the locked tag.
      expect(inCard('Ludo', Icons.lock_outline), findsNWidgets(2));
      expect(inCard('Benagil', Icons.lock_outline), findsNothing);
    });
  });

  testWidgets('tapping a card opens the zone and back returns', (tester) async {
    await openZones(tester, [benagil], owned: [2], then: () async {
      await tester.tap(find.text('Benagil'));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneDetailsScreen), findsOneWidget);
      expect(find.text('About Benagil'), findsOneWidget);
      expect(find.text(en.viewTrails), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.byType(ZoneDetailsScreen), findsNothing);
    });
  });

  testWidgets('an expired token is renewed before owned zones are requested',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': expired,
      'refresh_token': 'refresh',
    });
    final renewed = token(const Duration(hours: 2));

    await openSignedIn(
      tester,
      accepted: renewed,
      owned: [2],
      renewal: () async => http.Response('{"access": "$renewed"}', 200),
    );

    expectOwned(tester, 'Benagil');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cached_user_zones'), '[2]');
  });

  for (final (name, renewal) in <(String, Future<http.Response> Function())>[
    ('is rejected', () async => http.Response('{}', 401)),
    ('gets a server error', () async => http.Response('{}', 503)),
    ('cannot reach the API', () async => throw http.ClientException('down')),
  ]) {
    testWidgets('saved zones stay owned when the renewal $name',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': expired,
        'refresh_token': 'refresh',
        'cached_user_zones': '[1]',
      });

      await openSignedIn(tester, accepted: valid, renewal: renewal);

      expectOwned(tester, 'Ludo');
      expect(find.byType(OfflineBannerWidget), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_user_zones'), '[1]');
      expect(prefs.getString('refresh_token'), 'refresh');
    });
  }

  testWidgets('a valid token is used as it is', (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': valid,
      'refresh_token': 'refresh',
      'cached_user_zones': '[1]',
    });

    final requests =
        await openSignedIn(tester, accepted: valid, owned: [2]);

    expectOwned(tester, 'Benagil');
    expect(paths(requests), isNot(contains('/api/auth/token/refresh/')));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cached_user_zones'), '[2]');
  });

  testWidgets('saved zones stay owned when their request fails',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': valid,
      'cached_user_zones': '[1]',
    });

    await openSignedIn(tester, accepted: valid, userZonesStatus: 500);

    expectOwned(tester, 'Ludo');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cached_user_zones'), '[1]');
  });

  testWidgets('closing the list during a renewal is harmless', (tester) async {
    SharedPreferences.setMockInitialValues({
      'auth_token': expired,
      'refresh_token': 'refresh',
    });
    final renewal = Completer<http.Response>();

    await http.runWithClient(
      () async {
        await tester.pumpWidget(app(const ZonesListScreen()));
        await tester.pump();
        await tester.pumpWidget(app(const SizedBox()));
        renewal.complete(http.Response('{}', 503));
        await tester.pumpAndSettle();
      },
      () => MockClient((request) async =>
          request.url.path.endsWith('/auth/token/refresh/')
              ? renewal.future
              : request.url.path.endsWith('/user/zones/')
                  ? renewal.future.then((_) => http.Response('{}', 401))
                  : http.Response('[]', 200)),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a locked zone offers to buy it', (tester) async {
    await show(tester, ZoneDetailsScreen(zone: ludo));

    expect(find.text(en.viewTrails), findsNothing);
    await tester.tap(find.text(en.unlockZone));
    await tester.pump();

    expect(find.text(en.redirecting_purchase), findsOneWidget);
  });

  testWidgets('long names fit a small screen with large text', (tester) async {
    final long = zone(
      3,
      'Parque Natural da Ria Formosa e Ilhas Barreira',
      'Vila Real de Santo António',
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await http.runWithClient(() async {
      await show(tester, const ZonesListScreen());
      expect(tester.takeException(), isNull);

      await filterBy(tester, 'Vila Real de Santo António');
      expect(tester.takeException(), isNull);

      await show(tester, ZoneDetailsScreen(zone: long));
      expect(tester.takeException(), isNull);
    }, () => api([long], []));
  });
}
