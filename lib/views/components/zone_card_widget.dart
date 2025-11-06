import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/screens/zone_details_screen.dart';

class ZoneCardWidget extends StatefulWidget {
  final Map<String, dynamic> zone;
  final int index;

  const ZoneCardWidget(this.zone, this.index, {super.key});

  @override
  State<ZoneCardWidget> createState() => _ZoneCardWidgetState();
}

class _ZoneCardWidgetState extends State<ZoneCardWidget> {
  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final title = locale == "pt"
      ? (zone['translations']?['pt']?['name']?.toString() ?? '')
      : (zone['translations']?['en']?['name']?.toString() ?? '');
    final imageUrl = zone["thumbnail_url"]?.toString() ?? "";
    final municipalityName = zone["municipality"]?["name"]?.toString() ?? "-";
    final bool userHasZone = zone["user_have"] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 🖼️ Imagem
            CachedNetworkImage(
              imageUrl: imageUrl.isNotEmpty
                  ? imageUrl
                  : 'https://via.placeholder.com/400x200.png?text=No+Image',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 170,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade300,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Image.asset(
                "assets/images/default.jpg",
                fit: BoxFit.cover,
                width: double.infinity,
                height: 170,
              ),
            ),

            // Gradiente
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 📝 Texto
            Positioned(
              left: 16,
              bottom: 40,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    municipalityName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),

            // 🔒 Ícone de cadeado (se o user não possui a zona)
            if (!userHasZone)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white70,
                      size: 50,
                    ),
                  ),
                ),
              ),

            // 📌 Botão "See more"
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZoneDetailsScreen(zone: zone),
                    ),
                  );
                },
                child: Container(
                  height: 40,
                  color: Colors.black.withOpacity(0.7),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.seeMore,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
