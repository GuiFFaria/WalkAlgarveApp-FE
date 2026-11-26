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
import 'package:walk_algarve_app/views/screens/trail_map/trail_map_screen.dart';

// A blank 1x1 PNG, served for map tiles.
final tile = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

// Shaped like the API response: ids sit beside `properties`, not inside it.
final trail = jsonDecode('''
{
  "id": 6,
  "type": "Feature",
  "geometry": {"type": "LineString", "coordinates": [[-8.41, 37.09], [-8.42, 37.09]]},
  "properties": {
    "name": "Test trail",
    "distance_km": 1.0,
    "duration_min": 1,
    "trail_type": "LINEAR",
    "difficulty": "Easy",
    "pois": {"features": [
      {"id": 11, "geometry": {"type": "Point", "coordinates": [-8.41, 37.09]}, "properties": {"name": "A"}},
      {"id": 12, "geometry": {"type": "Point", "coordinates": [-8.42, 37.09]}, "properties": {"name": "B"}}
    ]}
  }
}
''');

void main() {
  testWidgets('a walked trail is saved to history with the points visited',
      (tester) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async => switch (call.method) {
        'isLocationServiceEnabled' => true,
        'checkPermission' => 2, // while in use
        _ => null,
      },
    );
    late MockStreamHandlerEventSink location;
    messenger.setMockStreamHandler(
      const EventChannel('flutter.baseflow.com/geolocator_updates'),
      MockStreamHandler.inline(
        onListen: (_, sink) {
          location = sink;
        },
        onCancel: (_) {},
      ),
    );
    SharedPreferences.setMockInitialValues({
      'auth_token': 'access',
      'user': '{"id": 7}',
    });
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      if (request.url.host != 'api.test') {
        return http.Response.bytes(tile, 200);
      }
      requests.add(request);
      return http.Response('{"id": 31}', request.method == 'POST' ? 201 : 200);
    });
    final translations = lookupAppLocalizations(const Locale('en'));

    await http.runWithClient(() async {
      Future<void> settle() => tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TrailMapScreen(trail: trail),
        ),
      ));
      await settle();
      await tester.tap(find.text(translations.start));
      await settle();

      // At the first point, then away from both.
      location.success({'latitude': 37.09, 'longitude': -8.41});
      await settle();
      location.success({'latitude': 37.09, 'longitude': -8.415});
      await settle();

      await tester.tap(find.text(translations.finish_trail_button));
      await settle();
      await tester.tap(find.text(translations.finish));
      // Cancelling a stream completes outside the test's fake clock.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await settle();
    }, () => client);

    expect(requests.map((r) => '${r.method} ${r.url.path}'), [
      'POST /api/users/7/history/',
      'PATCH /api/users/7/history/31/',
    ]);
    expect(jsonDecode(requests.first.body), {'trail': 6});
    final finished = jsonDecode(requests.last.body);
    expect(finished['pois_visited'], [11]);
    expect(finished['distance_actual_km'], closeTo(0.44, 0.02));
    expect(finished['completed'], isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
