import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/components/custom_drawer_widget.dart';

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

  /// 🔑 Carrega dados guardados nas SharedPreferences
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

  /// 🖼️ Escolher nova imagem de perfil
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

  /// 🚪 Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user");

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawerWidget(),
      appBar: CustomAppBarWidget(title: AppLocalizations.of(context)!.profile),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // 🖼️ Avatar com botão de edição
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
                      decoration: BoxDecoration(
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
              username ?? "Carregando...",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              email ?? "",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 30),

            // 📊 Estatísticas úteis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _ProfileStat(label: "Favoritos", value: "12"),
                      _ProfileStat(label: "Concluídos", value: "8"),
                      _ProfileStat(label: "Zonas", value: "3"),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ⚙️ Secção de opções
            _ProfileOption(
              icon: Icons.language,
              label: "Alterar idioma",
              onTap: () {
                // TODO: navegar para página de idioma
              },
            ),
            _ProfileOption(
              icon: Icons.lock,
              label: "Alterar palavra-passe",
              onTap: () {},
            ),
            _ProfileOption(
              icon: Icons.download,
              label: "Gerir mapas offline",
              onTap: () {},
            ),
            _ProfileOption(
              icon: Icons.history,
              label: "Histórico de trilhos",
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // 🚪 Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, color: Colors.white),
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

  const _ProfileStat({required this.label, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileOption({required this.icon, required this.label, required this.onTap, super.key});

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
