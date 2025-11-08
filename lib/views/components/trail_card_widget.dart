import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';

class TrailCardWidget extends StatefulWidget {
  final Map<String, dynamic> trail;
  final int index;
  final VoidCallback? onFavoriteToggled;

  const TrailCardWidget(this.trail, this.index, {super.key, this.onFavoriteToggled});

  @override
  State<TrailCardWidget> createState() => _TrailCardWidgetState();
}

class _TrailCardWidgetState extends State<TrailCardWidget> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    
    final rawFavorite = widget.trail["properties"]?["is_favorite"];

    bool parsedFavorite;
    if (rawFavorite is bool) {
      parsedFavorite = rawFavorite;
    } else if (rawFavorite is String) {
      parsedFavorite = rawFavorite.toLowerCase() == 'true';
    } else if (rawFavorite is num) {
      parsedFavorite = rawFavorite != 0;
    } else {
      parsedFavorite = false;
    }

    isFavorite = parsedFavorite;

    debugPrint("🔹 Trail ${widget.trail["id"]} favorito: $isFavorite");
  }

  Future<bool> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// ❤️ Alternar favorito e sincronizar com backend
  Future<void> _toggleFavorite() async {
    final trailId = widget.trail["id"];
    setState(() => isFavorite = !isFavorite);

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    // 🧼 Limpar token (tira aspas, espaços)
    if (token != null) {
      token = token.trim();
      if (token.startsWith('"') && token.endsWith('"')) {
        token = token.substring(1, token.length - 1);
      }
      token = token.trim();
    }

    debugPrint("🔑 Token enviado (40 chars): ${token != null ? token.substring(0, token.length > 40 ? 40 : token.length) : 'null'}");

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse("$baseUrl/trails/");
    final hasInternet = await _checkConnection();

    // 🗄️ Atualiza localmente no cache
    final cacheKey = "cached_trails_zone_${widget.trail["zone_id"] ?? "unknown"}";
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final List<Map<String, dynamic>> cachedTrails =
          List<Map<String, dynamic>>.from(jsonDecode(cached));
      for (final trail in cachedTrails) {
        if (trail["id"] == trailId) {
          trail["is_favorite"] = isFavorite;
        }
      }
      await prefs.setString(cacheKey, jsonEncode(cachedTrails));
    }

    // 📶 Offline → guarda pedido pendente
    if (!hasInternet || token == null || token.isEmpty) {
      final pendingKey = "pending_favorites";
      final pending = prefs.getString(pendingKey);
      final List<Map<String, dynamic>> pendingList =
          pending != null ? List<Map<String, dynamic>>.from(jsonDecode(pending)) : [];

      pendingList.add({
        "trail_id": trailId,
        "timestamp": DateTime.now().toIso8601String(),
      });

      await prefs.setString(pendingKey, jsonEncode(pendingList));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFavorite
              ? "Guardado como favorito (offline)"
              : "Removido dos favoritos (offline)"),
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onFavoriteToggled?.call();
      return;
    }

    // 🌐 Online → envia request POST
    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"trail_id": trailId}),
      );

      debugPrint("📤 Favorito response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFavorite
                ? "Adicionado aos favoritos"
                : "Removido dos favoritos"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sessão expirada — por favor faça login novamente."),
          ),
        );
      } else {
        debugPrint("⚠️ Erro ao sincronizar favorito: ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Erro ao enviar favorito: $e");
    }

    widget.onFavoriteToggled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final title = TranslationHelper.getValue(
      trail,
      locale,
      "name",
      fallback: "Untitled Trail",
    );

    final imageUrl = trail["properties"]?["thumbnail_url"]?.toString() ?? "";
    final distance = trail["properties"]?["distance_km"]?.toString() ?? "-";
    final duration = trail["properties"]?["duration_min"]?.toString() ?? "-";
    final type = trail["properties"]?["trail_type"]?.toString().toLowerCase() ?? "-";
    final difficulty = trail["properties"]?["difficulty"]?.toString() ?? "-";

    return GestureDetector(
      onTap: () {
        // TODO: Navegar para detalhes do trilho
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
              // 🖼️ Imagem do trilho
              CachedNetworkImage(
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : "https://via.placeholder.com/400x200.png?text=No+Image",
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

              // Gradiente escuro
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

              // ❤️ Ícone de favorito
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 28,
                  ),
                ),
              ),

              // 📝 Informação
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
                    Wrap(
                      spacing: 8,
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
        const SizedBox(width: 3),
        Text(
          text == "-" ? text : "$text$suffix",
          style: const TextStyle(color: Colors.white, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
