import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';
import 'package:walk_algarve_app/views/screens/trail_map_screen.dart';

class TrailDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trail;

  const TrailDetailsScreen({super.key, required this.trail});

  @override
  State<TrailDetailsScreen> createState() => _TrailDetailsScreenState();
}

class _TrailDetailsScreenState extends State<TrailDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final trail = widget.trail;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final title = TranslationHelper.getValue(
      trail,
      locale,
      "name",
      fallback: translations.untitled_trail,
    );

    final description = TranslationHelper.getValue(
      trail,
      locale,
      "description",
      fallback: trail["description"]?.toString() ?? translations.no_description,
    );

    final is_bike_friendly = trail["properties"]?["is_bike_friendly"];

    debugPrint("📘 Descrição traduzida: $is_bike_friendly");

    final thumbnail = trail["properties"]?["thumbnail_url"]?.toString() ??
        trail["image"]?.toString() ??
        "https://picsum.photos/800/600";

    final distance = trail["properties"]["distance_km"]?.toString() ?? "—";
    final duration = trail["properties"]["duration_min"]?.toString() ?? "—";
    final type = trail["properties"]?["trail_type"]?.toString().toLowerCase() ?? "—";
    final difficulty = trail["properties"]?["difficulty"]?.toString() ?? "—";

    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// LAYER 1: IMAGEM DE CAPA
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// LAYER 2: CARTÃO BRANCO
          Positioned(
            top: 280,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 30,
                    left: 18,
                    right: 18,
                    bottom: 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translations.description,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          description,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// LAYER 3: TÍTULO E ÍCONES
          Positioned(
            left: 20,
            right: 20,
            top: safeTop + 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 25,
                  runSpacing: 8,
                  children: [
                    _iconText(Icons.route, "$distance km"),
                    _iconText(Icons.timer, "$duration h"),
                    _iconText(Icons.cached, type),
                    _iconText(Icons.hiking, difficulty),
                    if (is_bike_friendly)
                      _iconText(Icons.pedal_bike, translations.bike_friendly)
                    else
                      _iconText(Icons.block, translations.no_bikes),
                  ],
                ),
              ],
            ),
          ),

          /// LAYER 4: BOTÃO DO MAPA
          Positioned(
            top: 255,
            right: 25,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TrailMapScreen(trail: trail),
                ));
              },
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map,
                  color: Color(0xFF4A90E2),
                  size: 32,
                ),
              ),
            ),
          ),

          /// LAYER 5: BOTÃO VOLTAR
          Positioned(
            top: safeTop + 10,
            left: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            shadows: [
              Shadow(color: Colors.black87, blurRadius: 6),
            ],
          ),
        )
      ],
    );
  }
}
