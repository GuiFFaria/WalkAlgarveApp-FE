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
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/trail_details/trail_details_screen.dart';
import 'package:walk_algarve_app/views/screens/trails_list/trails_list_screen.dart';
import 'package:walk_algarve_app/views/screens/zone_details/zone_details_screen.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

final en = lookupAppLocalizations(const Locale('en'));
final pt = lookupAppLocalizations(const Locale('pt'));

const zone = {'id': 3, 'name': 'Faro'};

Map<String, dynamic> trail({
  String name = 'Seven Valleys',
  Map<String, dynamic> facts = const {
    'distance_km': 12.0,
    'duration_min': 6,
    'trail_type': 'LINEAR',
    'difficulty': 'Moderate',
    'is_bike_friendly': true,
  },
  bool favorite = false,
}) =>
    {
      'id': 1,
      'properties': {
        'name': name,
        'description': 'A walk along the cliffs.',
        'thumbnail_url': '',
        'translations': <dynamic>[],
        'is_favorite': favorite,
        ...facts,
      },
    };

void connectivity(String result) {
  TestWidgetsFlutterBinding.ensureInitialized()
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/connectivity'),
        (_) async => [result],
      );
}

Future<void> show(
  WidgetTester tester,
  Widget screen, {
  String language = 'en',
}) async {
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => LocaleProvider()..setLocale(Locale(language)),
    child: MaterialApp(
      theme: AppTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

/// Opens the trail list against a fake API and returns what it received.
Future<List<http.Request>> openList(
  WidgetTester tester,
  List<Map<String, dynamic>> trails, {
  required Future<void> Function() then,
}) async {
  final requests = <http.Request>[];
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await http.runWithClient(() async {
    await show(tester, const TrailsListScreen(zone: zone));
    await then();
  },
      () => MockClient((request) async {
            requests.add(request);
            return request.method == 'POST'
                ? http.Response('{}', 201)
                : http.Response(jsonEncode(trails), 200);
          }));
  return requests;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'token'});
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    connectivity('wifi');
  });

  testWidgets('the list names the zone and shows each trail\'s facts',
      (tester) async {
    await openList(tester, [trail()], then: () async {
      expect(find.text(en.zone_subtitle('Faro')), findsOneWidget);
      for (final fact in ['Seven Valleys', '12 km', '6 h', 'Linear']) {
        expect(find.text(fact), findsOneWidget);
      }
      expect(find.text(en.difficulty_moderate), findsOneWidget);
      expect(find.text(en.trail_photo), findsOneWidget);
      expect(find.byType(OfflineBannerWidget), findsNothing);
    });
  });

  testWidgets('facts follow the language', (tester) async {
    final halfway = trail(facts: {'distance_km': 7.5, 'difficulty': 'Hard'});

    await show(tester, TrailDetailsScreen(trail: halfway), language: 'pt');

    expect(find.text('7,5 km'), findsOneWidget);
    expect(find.text(pt.difficulty_hard), findsOneWidget);
  });

  testWidgets('an unknown difficulty is shown as sent', (tester) async {
    final odd = trail(facts: {'difficulty': 'Expert'});

    await show(tester, TrailDetailsScreen(trail: odd), language: 'pt');

    expect(find.text('Expert'), findsOneWidget);
  });

  testWidgets('details show the facts, bikes and the whole description',
      (tester) async {
    await show(tester, TrailDetailsScreen(trail: trail()));

    for (final fact in ['12 km', '6 h', 'Linear', en.difficulty_moderate]) {
      expect(find.text(fact), findsOneWidget);
    }
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.text(en.bike_friendly), findsOneWidget);
    expect(find.text('A walk along the cliffs.'), findsOneWidget);
    expect(find.text(en.view_map), findsOneWidget);
  });

  testWidgets('a circular trail has a loop icon and says no bikes',
      (tester) async {
    final loop = trail(
      facts: {'trail_type': 'CIRCULAR', 'is_bike_friendly': false},
    );

    await show(tester, TrailDetailsScreen(trail: loop));

    expect(find.byIcon(Icons.loop), findsOneWidget);
    expect(find.text('Circular'), findsOneWidget);
    expect(find.text(en.no_bikes), findsOneWidget);
  });

  testWidgets('missing facts and bike information are left out',
      (tester) async {
    await show(tester, TrailDetailsScreen(trail: trail(facts: {})));

    expect(tester.takeException(), isNull);
    expect(find.textContaining(' km'), findsNothing);
    expect(find.textContaining(' h'), findsNothing);
    expect(find.text(en.bike_friendly), findsNothing);
    expect(find.text(en.no_bikes), findsNothing);
  });

  testWidgets('tapping a card opens the trail and back returns',
      (tester) async {
    await openList(tester, [trail()], then: () async {
      await tester.tap(find.text('Seven Valleys'));
      await tester.pumpAndSettle();
      expect(find.byType(TrailDetailsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(TrailDetailsScreen), findsNothing);
    });
  });

  testWidgets('the heart saves a favorite online', (tester) async {
    final requests = await openList(tester, [trail()], then: () async {
      await tester.tap(find.byTooltip(en.favorite_add));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text(en.favorite_added), findsOneWidget);
      expect(find.byType(TrailDetailsScreen), findsNothing);
    });

    final saved = requests.singleWhere((r) => r.method == 'POST');
    expect(jsonDecode(saved.body), {'trail_id': 1});
    expect(saved.headers['Authorization'], 'Bearer token');
  });

  testWidgets('a favorite changed offline is queued', (tester) async {
    connectivity('none');
    SharedPreferences.setMockInitialValues({
      'auth_token': 'token',
      'cached_trails_zone_3': jsonEncode([trail(favorite: true)]),
    });

    final requests = await openList(tester, [], then: () async {
      expect(find.text(en.offline_saved_data), findsOneWidget);

      await tester.tap(find.byTooltip(en.favorite_remove));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text(en.favorite_removed_offline), findsOneWidget);
    });

    final prefs = await SharedPreferences.getInstance();
    final queued = jsonDecode(prefs.getString('pending_favorites')!);
    expect(queued.single['trail_id'], 1);
    expect(requests, isEmpty);
  });

  testWidgets('an empty list says there are no trails', (tester) async {
    await openList(tester, [], then: () async {
      expect(find.text(en.no_trails_available), findsOneWidget);
    });
  });

  testWidgets('pull to refresh asks for the trails again', (tester) async {
    final requests = await openList(tester, [trail()], then: () async {
      await tester.fling(find.byType(ListView), const Offset(0, 500), 1000);
      await tester.pumpAndSettle();
    });

    expect(requests.where((r) => r.method == 'GET'), hasLength(2));
  });

  testWidgets('a long description scrolls below the photo', (tester) async {
    final wordy = trail(facts: {'description': 'Cliffs and coves. ' * 200});

    for (final screen in <Widget>[
      TrailDetailsScreen(trail: wordy),
      ZoneDetailsScreen(zone: {
        'id': 3,
        'translations': {
          'en': {'description': 'Cliffs and coves. ' * 200},
        },
      }),
    ]) {
      await show(tester, screen);
      final text = find.textContaining('Cliffs and coves.');
      final before = tester.getTopLeft(text).dy;

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(text).dy, lessThan(before));
      // The scrolling area, which clips its text, starts below the photo.
      expect(
        tester.getTopLeft(find.byType(SingleChildScrollView)).dy,
        greaterThanOrEqualTo(270),
      );
    }
  });

  testWidgets('long names fit a small screen with large text', (tester) async {
    final long = trail(
      name: 'Percurso Pedestre das Falésias e Lagoas do Barlavento Algarvio',
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await http.runWithClient(() async {
      await show(tester, const TrailsListScreen(zone: zone), language: 'pt');
      expect(tester.takeException(), isNull);

      await show(tester, TrailDetailsScreen(trail: long), language: 'pt');
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response(jsonEncode([long]), 200)));
  });
}
