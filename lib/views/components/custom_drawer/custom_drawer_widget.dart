import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/screens/profile/profile_screen.dart';
import 'package:walk_algarve_app/views/screens/settings/settings_screen.dart';
import 'package:walk_algarve_app/views/screens/zones_list/zones_list_screen.dart';

class CustomDrawerWidget extends StatefulWidget {
  const CustomDrawerWidget({super.key});

  @override
  State<CustomDrawerWidget> createState() => _CustomDrawerWidgetState();
}

class _CustomDrawerWidgetState extends State<CustomDrawerWidget> {
  String username = "Explorador";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null && userData.isNotEmpty) {
      try {
        final user = jsonDecode(userData);
        setState(() {
          username = user["username"] ?? user["name"] ?? "Explorador";
        });
      } catch (e) {
        debugPrint("❌ Erro ao ler utilizador: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Drawer(
      elevation: 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(26)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9FAFB), Color(0xFFEAF6F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1BA6A1), Color(0xFF138C89)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(26),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, right: 12, top: 50, bottom: 30),
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 35,
                      backgroundImage: AssetImage('assets/images/profile_placeholder.jpg'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          translations.welcome,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 22,
                    tooltip: translations.close_menu,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ListView(
                  children: [
                    _sectionTitle(translations.explore),
                    _drawerItem(
                      icon: Icons.terrain,
                      label: translations.zones,
                      onTap: () => _navigate(context, const ZonesListScreen()),
                    ),
                    _drawerItem(
                      icon: Icons.history,
                      label: translations.history,
                      onTap: () => _navigate(context, const SettingsScreen()),
                    ),
                    const SizedBox(height: 10),
                    _sectionTitle(translations.account_section),
                    _drawerItem(
                      icon: Icons.person_outline,
                      label: translations.profile,
                      onTap: () => _navigate(context, const ProfileScreen()),
                    ),
                    _drawerItem(
                      icon: Icons.favorite_border,
                      label: translations.favorites,
                      onTap: () => _navigate(context, const SettingsScreen()),
                    ),
                    const SizedBox(height: 10),
                    _sectionTitle(translations.settings),
                    _drawerItem(
                      icon: Icons.settings_outlined,
                      label: translations.settings,
                      onTap: () => _navigate(context, const SettingsScreen()),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Walk Algarve v1.0.0",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Icon(Icons.hiking, size: 18, color: Color(0xFF1BA6A1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: const Color(0xFF1BA6A1).withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1BA6A1)),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}
