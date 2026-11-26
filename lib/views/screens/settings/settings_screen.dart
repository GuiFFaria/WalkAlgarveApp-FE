import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/screens/coming_soon/coming_soon_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonScreen(
      title: AppLocalizations.of(context)!.settings,
      icon: Icons.settings_outlined,
    );
  }
}
