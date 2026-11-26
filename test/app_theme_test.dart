import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/components/custom_appbar/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (max(x, y) + 0.05) / (min(x, y) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light theme uses the design tokens', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F6F3));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(theme.colorScheme.primary, const Color(0xFF0B6B72));
    expect(theme.colorScheme.onSurface, const Color(0xFF13262B));
    expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.fontFamily);
  });

  test('dark theme uses the design tokens', () {
    final theme = AppTheme.dark;

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0E1719));
    expect(theme.colorScheme.surface, const Color(0xFF162225));
    expect(theme.colorScheme.primary, const Color(0xFF5CC4C2));
    expect(theme.colorScheme.onSurface, const Color(0xFFE8F0EF));
    expect(theme.textTheme.bodyMedium!.fontFamily, AppTheme.fontFamily);
  });

  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    test('$name theme keeps text readable', () {
      final c = theme.colorScheme;
      final background = theme.scaffoldBackgroundColor;
      final pairs = {
        'text on background': (c.onSurface, background),
        'text on surface': (c.onSurface, c.surface),
        'muted text on background': (c.onSurfaceVariant, background),
        'primary text on background': (c.primary, background),
        'primary button': (c.onPrimary, c.primary),
        'primary chip': (c.onPrimaryContainer, c.primaryContainer),
        'accent chip': (c.onSecondaryContainer, c.secondaryContainer),
        'success banner': (c.onTertiaryContainer, c.tertiaryContainer),
        'error banner': (c.onErrorContainer, c.errorContainer),
      };

      pairs.forEach((use, colors) {
        expect(
          contrast(colors.$1, colors.$2),
          greaterThanOrEqualTo(4.5),
          reason: use,
        );
      });
    });
  }

  test('every font weight is bundled', () async {
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      final font = await rootBundle.load(
        'assets/fonts/PlusJakartaSans-$weight.ttf',
      );

      expect(font.lengthInBytes, greaterThan(0), reason: weight);
    }
  });

  testWidgets('the top bar takes its colors from the theme', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(appBar: CustomAppBarWidget(title: 'Zones')),
      ),
    ));

    final bar = tester.widget<Material>(find
        .descendant(of: find.byType(AppBar), matching: find.byType(Material))
        .first);
    final title = DefaultTextStyle.of(tester.element(find.text('Zones')));

    expect(bar.color, AppTheme.dark.scaffoldBackgroundColor);
    expect(title.style.color, AppTheme.dark.colorScheme.onSurface);
  });
}
