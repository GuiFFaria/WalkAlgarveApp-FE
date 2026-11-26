import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/tab_bar/app_tab_bar_widget.dart';
import 'package:walk_algarve_app/views/screens/coming_soon/coming_soon_screen.dart';
import 'package:walk_algarve_app/views/screens/profile/profile_screen.dart';
import 'package:walk_algarve_app/views/screens/zones_list/zones_list_screen.dart';

/// The top-level screens behind the bottom tab bar. Screens pushed from a tab
/// cover the bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const ZonesListScreen(),
          ComingSoonScreen(
            title: translations.favorites,
            icon: Icons.favorite_border,
          ),
          ComingSoonScreen(title: translations.history, icon: Icons.history),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppTabBarWidget(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
