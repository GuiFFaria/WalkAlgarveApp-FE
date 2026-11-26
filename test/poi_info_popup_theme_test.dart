import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/poi_info_popup/poi_info_popup.dart';
import 'package:walk_algarve_app/views/theme/app_theme.dart';

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('the point of interest popup is readable in $name mode',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PoiInfoPopup(
            poi: const {
              'properties': {'name': 'Lagoon'},
            },
            onClose: () {},
          ),
        ),
      ));

      final box = tester.widget<Container>(find
          .ancestor(of: find.text('Lagoon'), matching: find.byType(Container))
          .last);
      final background = (box.decoration! as BoxDecoration).color!;
      final text = tester.widget<RichText>(find.descendant(
        of: find.text('Lagoon'),
        matching: find.byType(RichText),
      ));

      final a = background.computeLuminance();
      final b = text.text.style!.color!.computeLuminance();
      final contrast = a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);

      expect(background, theme.colorScheme.surface);
      expect(contrast, greaterThanOrEqualTo(4.5));
    });
  }
}
