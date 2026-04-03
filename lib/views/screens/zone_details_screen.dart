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
    final translations = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final imageUrl = zone["thumbnail_url"] ?? "";
    final title = locale == "pt"
        ? (zone['translations']?['pt']?['name']?.toString() ?? '')
        : (zone['translations']?['en']?['name']?.toString() ?? '');
    final description = locale == "pt"
        ? (zone['translations']?['pt']?['description']?.toString() ?? translations.no_description)
        : (zone['translations']?['en']?['description']?.toString() ?? translations.no_description);
    final bool userHasZone = zone["user_have"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
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
                      translations.aboutZone,
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
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailsListScreen(zoneId: zone["id"]),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(translations.redirecting_purchase),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                userHasZone ? translations.viewTrails : translations.unlockZone,
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
