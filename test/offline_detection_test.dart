import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/screens/register/register_screen.dart';

const connectivityChannel =
    MethodChannel('dev.fluttercommunity.plus/connectivity');

void reportConnectivity(WidgetTester tester, List<String> results) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    connectivityChannel,
    (_) async => results,
  );
}

void main() {
  testWidgets('registering while offline shows the offline notice',
      (tester) async {
    reportConnectivity(tester, ['none']);
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api');
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RegisterScreen(),
    ));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'hiker');
    await tester.enterText(fields.at(1), 'hiker@example.com');
    await tester.enterText(fields.at(2), 'testpass123');
    await tester.enterText(fields.at(3), 'testpass123');
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final translations = lookupAppLocalizations(const Locale('en'));
    expect(find.text(translations.register_requires_internet), findsOneWidget);
  });
}
