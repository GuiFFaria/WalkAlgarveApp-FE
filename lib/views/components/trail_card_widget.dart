import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';

class TrailCardWidget extends StatefulWidget {
  final Map<String, dynamic> trail;
  final int index;

  const TrailCardWidget(this.trail, this.index, {super.key});

  @override
  State<TrailCardWidget> createState() => _TrailCardWidgetState();
}

class _TrailCardWidgetState extends State<TrailCardWidget> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.trail["favorite"] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;

    final locale = context.watch<LocaleProvider>().locale.languageCode;


    final title = TranslationHelper.getValue(
      trail,
      locale,
      "name",
      fallback: 'Untitled Trail',
    );
    final imageUrl = trail['properties']["thumbnail_url"]?.toString() ?? "";
    final distance = trail['properties']["distance_km"]?.toString() ?? "-";
    final duration = trail['properties']["duration_min"]?.toString() ?? "-";
    final type = trail['properties']["trail_type"]?.toString().toLowerCase() ?? "-";
    final difficulty = trail['properties']["difficulty"]?.toString() ?? "-";

    return GestureDetector(
      onTap: () {
        // Ir para detalhes
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 🖼️ Imagem com cache offline automático
              CachedNetworkImage(
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/400x200.png?text=No+Image',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  "assets/default.jpg",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // Gradiente escuro para legibilidade do texto
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

              // ❤️ Favorito
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // 📝 Info
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 🔹 Aqui está a correção principal (Wrap em vez de Row)
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        _info(Icons.place, distance, suffix: " km"),
                        _info(Icons.timer, duration, suffix: " h"),
                        _info(Icons.loop, type),
                        _info(Icons.flag, difficulty),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text, {String suffix = ""}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 13),
        Text(
          text == "-" ? text : "$text$suffix",
          style: const TextStyle(color: Colors.white, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
