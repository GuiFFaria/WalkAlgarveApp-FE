import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/custom_appbar/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/helpers/trail_cache.dart';
import 'package:walk_algarve_app/views/screens/login/login_screen.dart';
import 'package:walk_algarve_app/views/screens/settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? email;
  File? profileImageFile;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("user");

    if (userJson != null) {
      final user = jsonDecode(userJson);
      setState(() {
        username = user["username"] ?? "User";
        email = user["email"] ?? "No email available";
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        profileImageFile = File(picked.path);
      });

      // TODO: enviar imagem ao backend se aplicável
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user");
    await TrailCache.clear();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBarWidget(title: translations.profile),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageFile != null
                      ? FileImage(profileImageFile!)
                      : AssetImage("assets/images/profile_placeholder.jpg")
                          as ImageProvider,
                ),

                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              username ?? translations.loading,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              email ?? "",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (label, value) in [
                        (translations.favorites, "12"),
                        (translations.completed, "8"),
                        (translations.zones, "3"),
                      ])
                        Expanded(
                          child: _ProfileStat(label: label, value: value),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            _ProfileOption(
              icon: Icons.language,
              label: translations.change_language,
              onTap: () {
                // TODO: navegar para página de idioma
              },
            ),
            _ProfileOption(
              icon: Icons.lock,
              label: translations.change_password,
              onTap: () {},
            ),
            _ProfileOption(
              icon: Icons.download,
              label: translations.manage_offline_maps,
              onTap: () {},
            ),
            _ProfileOption(
              icon: Icons.history,
              label: translations.trail_history_option,
              onTap: () {},
            ),
            _ProfileOption(
              icon: Icons.settings,
              label: translations.settings,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                label: Text(
                  translations.logout,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
