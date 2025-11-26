import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/trails_list_screen.dart';

class ZoneDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ZoneDetailsScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final imageUrl = zone["thumbnail_url"] ?? "";
    final title = locale == "pt"
        ? (zone['translations']?['pt']?['name']?.toString() ?? '')
        : (zone['translations']?['en']?['name']?.toString() ?? '');
    final description = locale == "pt"
        ? (zone['translations']?['pt']?['description']?.toString() ??
            'Sem descrição disponível.')
        : (zone['translations']?['en']?['description']?.toString() ??
            'No description available');
    final bool userHasZone = zone["user_have"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🖼️ Imagem topo com loading
          SizedBox(
            width: double.infinity,
            height: 180,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFF1BA6A1)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Image.asset(
                      "assets/default.jpg",
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset("assets/default.jpg", fit: BoxFit.cover),
          ),

          // 📄 Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.aboutZone,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 80), // espaço para botão
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 📌 Botão no fundo
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: userHasZone ? Colors.green : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (userHasZone) {
                  // Navega para trilhos da zona
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailsListScreen(zoneId: zone["id"]),
                    ),
                  );
                } else {
                  // Lógica de compra (p.ex. abrir checkout)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Redirecting to purchase..."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                userHasZone
                    ? AppLocalizations.of(context)!.viewTrails
                    : AppLocalizations.of(context)!.unlockZone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
