import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/tab_bar/app_tab_bar_widget.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/home/home_screen.dart';
import 'package:walk_algarve_app/views/screens/login/login_screen.dart';
import 'package:walk_algarve_app/views/screens/settings/settings_screen.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

final pt = lookupAppLocalizations(const Locale('pt'));
final en = lookupAppLocalizations(const Locale('en'));

Finder tab(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Future<void> openApp(WidgetTester tester, {ThemeData? theme}) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ],
    child: Consumer<LocaleProvider>(
      builder: (_, locale, __) => MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeScreen(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user': '{"username": "hiker", "email": "hiker@example.com"}',
    });
    dotenv.testLoad(fileInput: 'API_BASE_URL=http://api.test/api');
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['none'],
        );
  });

  testWidgets('opens on Explore with four tabs and no side menu',
      (tester) async {
    await openApp(tester);

    for (final label in [pt.explore, pt.favorites, pt.history, pt.profile]) {
      expect(tab(label), findsOneWidget);
    }
    expect(selectedTab(tester), 0);
    expect(find.text(pt.no_zones_available), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('each tab shows its screen and is highlighted', (tester) async {
    await openApp(tester);

    await tester.tap(tab(pt.favorites));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 1);
    expect(find.text(pt.coming_soon), findsOneWidget);

    await tester.tap(tab(pt.history));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 2);
    expect(find.text(pt.coming_soon), findsOneWidget);

    await tester.tap(tab(pt.profile));
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 3);
    expect(find.text('hiker@example.com'), findsOneWidget);
    expect(find.text(pt.coming_soon), findsNothing);
  });

  testWidgets('the language switch translates the tabs', (tester) async {
    await openApp(tester);

    await tester.tap(find.text(' / '));
    await tester.pumpAndSettle();

    expect(tab(en.explore), findsOneWidget);
    expect(tab(pt.explore), findsNothing);
  });

  testWidgets('Settings opens from Profile, above the tab bar',
      (tester) async {
    await openApp(tester);
    await tester.tap(tab(pt.profile));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(pt.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pt.settings));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(AppTabBarWidget), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(selectedTab(tester), 3);
  });

  testWidgets('logging out leaves the tabs and logging in returns to them',
      (tester) async {
    await http.runWithClient(() async {
      await openApp(tester);
      await tester.tap(tab(pt.profile));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(pt.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.logout));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AppTabBarWidget), findsNothing);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'hiker@example.com');
      await tester.enterText(fields.at(1), 'testpass123');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(selectedTab(tester), 0);
    },
        () => MockClient((_) async => http.Response(
              '{"access": "token", "refresh": "refresh", "user": {}}',
              200,
            )));
  });

  testWidgets('no way back to login after registering and logging in',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );

    Future<void> submit(List<String> values) async {
      final fields = find.byType(TextField);
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(fields.at(i), values[i]);
      }
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }

    await http.runWithClient(() async {
      await openApp(tester);
      await tester.tap(tab(pt.profile));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(pt.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text(pt.logout));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(pt.register));
      await tester.tap(find.text(pt.register));
      await tester.pumpAndSettle();
      await submit(
          ['hiker', 'hiker@example.com', 'testpass123', 'testpass123']);
      await submit(['hiker@example.com', 'testpass123']);

      expect(selectedTab(tester), 0);
      expect(find.byType(BackButton), findsNothing);
    },
        () => MockClient((_) async => http.Response(
              '{"access": "token", "refresh": "refresh", "user": {}}',
              200,
            )));
  });

  testWidgets('every tab fits a small screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await openApp(tester);

    for (final label in [pt.favorites, pt.history, pt.profile, pt.explore]) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('the tab bar follows the $name theme', (tester) async {
      await openApp(tester, theme: theme);

      Color labelColor(String label) => tester
          .widget<RichText>(find.descendant(
            of: tab(label),
            matching: find.byType(RichText),
          ))
          .text
          .style!
          .color!;

      final surface = tester.widget<Material>(find
          .ancestor(
            of: find.byType(NavigationBar),
            matching: find.byType(Material),
          )
          .first);

      expect(surface.color, theme.colorScheme.surface);
      expect(labelColor(pt.explore), theme.colorScheme.primary);
      expect(labelColor(pt.history), theme.colorScheme.onSurfaceVariant);
    });
  }
}
