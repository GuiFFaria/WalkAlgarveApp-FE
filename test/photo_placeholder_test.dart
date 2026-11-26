import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/components/trail_card/trail_card_widget.dart';
import 'package:walk_algarve_app/views/components/zone_card/zone_card_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/trail_details/trail_details_screen.dart';
import 'package:walk_algarve_app/views/screens/zone_details/zone_details_screen.dart';

const missingPhoto = 'http://photos.test/missing.jpg';

final placeholder = find.byType(PhotoPlaceholderWidget);

Map<String, dynamic> zone(String photo) => {'thumbnail_url': photo};

Map<String, dynamic> trail(String? photo) => {
      'id': 1,
      'properties': {
        'thumbnail_url': photo,
        'distance_km': 12,
        'is_bike_friendly': false,
      },
    };

Future<void> show(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(ChangeNotifierProvider(
    create: (_) => LocaleProvider(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: screen),
    ),
  ));
  // Image loading runs outside the test's fake clock.
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final screens = <String, Widget>{
    'zone details without a photo': ZoneDetailsScreen(zone: zone('')),
    'zone details with a failed photo':
        ZoneDetailsScreen(zone: zone(missingPhoto)),
    'trail details with an empty photo address':
        TrailDetailsScreen(trail: trail('')),
    'trail details without a photo address':
        TrailDetailsScreen(trail: trail(null)),
    'trail details with a failed photo':
        TrailDetailsScreen(trail: trail(missingPhoto)),
    'a zone card without a photo': ZoneCardWidget(zone('')),
    'a trail card without a photo': TrailCardWidget(trail('')),
  };

  screens.forEach((name, screen) {
    testWidgets('$name shows the placeholder', (tester) async {
      await show(tester, screen);

      expect(tester.takeException(), isNull);
      expect(placeholder, findsOneWidget);
    });
  });
}
