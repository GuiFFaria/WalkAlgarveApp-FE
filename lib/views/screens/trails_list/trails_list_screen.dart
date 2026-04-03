import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:walk_algarve_app/views/components/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/components/custom_drawer_widget.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/trail_card_widget.dart';


class TrailsListScreen extends StatefulWidget {
  final int zoneId;

  const TrailsListScreen({super.key, required this.zoneId});

  @override
  State<TrailsListScreen> createState() => _TrailsListScreenState();
}

class _TrailsListScreenState extends State<TrailsListScreen> {
  List<Map<String, dynamic>> trails = [];
  bool isLoading = true;
  bool isOffline = false;

  String get cacheKey => "cached_trails_zone_${widget.zoneId}";
  String get pendingKey => "pending_favorites";

  @override
  void initState() {
    super.initState();
    loadTrails();
  }

  /// 🔌 Verifica conexão
  Future<bool> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 🌐 Carrega trilhos (API se online, cache se offline)
  Future<void> loadTrails() async {
    setState(() => isLoading = true);
    final hasInternet = await checkConnection();

    if (hasInternet) {
      await fetchTrailsFromApi();
      await syncPendingFavorites();
    } else {
      await loadTrailsFromCache();
    }

    setState(() => isLoading = false);
  }

  /// 🛰️ Busca trilhos da API
  Future<void> fetchTrailsFromApi() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse("$baseUrl/trails/?zone=${widget.zoneId}");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        url,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          debugPrint("✅ Trilhos carregados da API (${decoded.length})");
          setState(() {
            trails = List<Map<String, dynamic>>.from(decoded);
            isOffline = false;
          });
          await prefs.setString(cacheKey, jsonEncode(trails));
        } else if (decoded is Map && decoded.containsKey("features")) {
          final decodedTrails = decoded["features"] as List<dynamic>;
          setState(() {
            trails = List<Map<String, dynamic>>.from(decodedTrails);
            isOffline = false;
          });
          await prefs.setString(cacheKey, jsonEncode(trails));
        } else {
          throw Exception("Formato inesperado: ${decoded.runtimeType}");
        }
      } else {
        debugPrint("⚠️ Falha no carregamento da API: ${response.statusCode}");
        await loadTrailsFromCache();
      }
    } catch (e) {
      debugPrint("⚠️ Erro API: $e");
      await loadTrailsFromCache();
    }
  }

  /// 💾 Carrega do cache
  Future<void> loadTrailsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      setState(() {
        trails = List<Map<String, dynamic>>.from(jsonDecode(cached));
        isOffline = true;
      });
    } else {
      trails = [];
    }
  }

  /// 🔁 Sincroniza favoritos pendentes (quando volta online)
  Future<void> syncPendingFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(pendingKey);
    if (pending == null) return;

    final List<Map<String, dynamic>> pendingList =
        List<Map<String, dynamic>>.from(jsonDecode(pending));

    if (pendingList.isEmpty) return;

    final token = prefs.getString('auth_token');
    if (token == null) return;

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse("$baseUrl/trails/");

    for (final fav in pendingList) {
      try {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({"trail_id": fav['trail_id']}),
        );
        debugPrint("✅ Sincronizado trail ${fav['trail_id']}");
      } catch (e) {
        debugPrint("⚠️ Erro ao sincronizar trail ${fav['trail_id']}: $e");
      }
    }

    await prefs.remove(pendingKey);
  }

  /// 🔄 Callback quando o estado de favorito muda no TrailCardWidget
  void onFavoriteToggled() async {
    // Atualiza cache e estado
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      setState(() {
        trails = List<Map<String, dynamic>>.from(jsonDecode(cached));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawerWidget(),
      appBar: CustomAppBarWidget(
        title: isOffline
            ? "${AppLocalizations.of(context)!.trails} (Offline)"
            : AppLocalizations.of(context)!.trails,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : trails.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: loadTrails,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: trails.length,
                      itemBuilder: (context, index) {
                        final trail = trails[index];
                        return TrailCardWidget(
                          trail,
                          index,
                          onFavoriteToggled: onFavoriteToggled, // ✅ callback
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(AppLocalizations.of(context)!.no_trails_available),
                  ),
      ),
    );
  }
}
