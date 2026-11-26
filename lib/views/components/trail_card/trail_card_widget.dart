import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/info_chip/info_chip_widget.dart';
import 'package:walk_algarve_app/views/components/photo_placeholder/photo_placeholder_widget.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/helpers/connectivity_helper.dart';
import 'package:walk_algarve_app/views/helpers/trail_helper.dart';
import 'package:walk_algarve_app/views/helpers/translations_helper.dart';
import 'package:walk_algarve_app/views/screens/trail_details/trail_details_screen.dart';

class TrailCardWidget extends StatefulWidget {
  final Map<String, dynamic> trail;
  final VoidCallback? onFavoriteToggled;

  const TrailCardWidget(
    this.trail, {
    super.key,
    this.onFavoriteToggled,
  });

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

  Future<void> _toggleFavorite() async {
    final translations = AppLocalizations.of(context)!;
    final trailId = widget.trail["id"];
    setState(() => isFavorite = !isFavorite);

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("auth_token");

    if (token != null) {
      token = token.trim();
      if (token.startsWith('"') && token.endsWith('"')) {
        token = token.substring(1, token.length - 1);
      }
      token = token.trim();
    }

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse("$baseUrl/trails/");
    final hasInternet = await ConnectivityHelper.hasConnection();

    final cacheKey =
        "cached_trails_zone_${widget.trail["zone_id"] ?? "unknown"}";
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

    if (!hasInternet || token == null || token.isEmpty) {
      final pendingKey = "pending_favorites";
      final pending = prefs.getString(pendingKey);
      final List<Map<String, dynamic>> pendingList = pending != null
          ? List<Map<String, dynamic>>.from(jsonDecode(pending))
          : [];

      pendingList.add({
        "trail_id": trailId,
        "timestamp": DateTime.now().toIso8601String(),
      });

      await prefs.setString(pendingKey, jsonEncode(pendingList));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? translations.favorite_added_offline
                : translations.favorite_removed_offline,
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onFavoriteToggled?.call();
      return;
    }

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"trail_id": trailId}),
      );

      debugPrint(
        "📤 Favorito response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite
                  ? translations.favorite_added
                  : translations.favorite_removed,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(translations.session_expired)));
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
    final translations = AppLocalizations.of(context)!;
    final trail = widget.trail;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final title = TranslationHelper.getValue(
      trail,
      locale,
      "name",
      fallback: translations.untitled_trail,
    );
    final photo = TrailHelper.photo(trail);
    final placeholder =
        PhotoPlaceholderWidget(caption: translations.trail_photo);
    final difficulty = TrailHelper.difficulty(trail, translations);
    final facts = [
      TrailHelper.distance(trail, locale),
      TrailHelper.duration(trail, locale),
      TrailHelper.type(trail),
    ].nonNulls;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrailDetailsScreen(trail: trail),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 220,
                  child: photo.isEmpty
                      ? placeholder
                      : CachedNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => placeholder,
                        ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final fact in facts)
                            InfoChipWidget(
                              label: fact,
                              background: colors.surfaceContainerHighest,
                              foreground: colors.onSurface,
                            ),
                          if (difficulty != null)
                            InfoChipWidget(
                              label: difficulty,
                              background: colors.primaryContainer,
                              foreground: colors.onPrimaryContainer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              tooltip: isFavorite
                  ? translations.favorite_remove
                  : translations.favorite_add,
              onPressed: _toggleFavorite,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: isFavorite ? colors.error : colors.onSurface,
                fixedSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
