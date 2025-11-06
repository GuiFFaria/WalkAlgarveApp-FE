import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:walk_algarve_app/views/components/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/components/custom_drawer_widget.dart';
import 'package:walk_algarve_app/views/components/trail_card_widget.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class TrailsListScreen extends StatefulWidget {
  final int zoneId;

  const TrailsListScreen({
    super.key,
    required this.zoneId,
  });

  @override
  State<TrailsListScreen> createState() => _TrailsListScreenState();
}

class _TrailsListScreenState extends State<TrailsListScreen> {
  List<dynamic> trails = [];
  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    loadTrails();
  }

  /// Cache key única por zona
  String get cacheKey => "cached_trails_zone_${widget.zoneId}";

  /// 🔌 Verifica a conexão à internet
  Future<bool> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 🌐 Carrega trilhos (API se online, cache se offline)
  Future<void> loadTrails() async {
    setState(() => isLoading = true);

    final hasInternet = await checkConnection();

    if (hasInternet) {
      debugPrint("✅ Online - Fetching trails for zone ${widget.zoneId}");
      await fetchTrailsFromApi();
    } else {
      debugPrint("⚠️ Offline - Loading cached trails for zone ${widget.zoneId}");
      await loadTrailsFromCache();
    }

    setState(() => isLoading = false);
  }

  /// 🛰️ Busca trilhos da API e guarda em cache
  Future<void> fetchTrailsFromApi() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse("$baseUrl/trails/?zone=${widget.zoneId}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
        final decodedTrails = decodedJson['features'] as List<dynamic>;

        setState(() {
          trails = List<Map<String, dynamic>>.from(decodedTrails);
          isOffline = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(trails));

        debugPrint("💾 ${trails.length} trilhos guardados em cache (zona ${widget.zoneId}).");
      } else {
        debugPrint("❌ Erro ao buscar trilhos: ${response.body}");
        await loadTrailsFromCache();
      }
    } catch (e) {
      debugPrint("⚠️ Erro de conexão: $e");
      await loadTrailsFromCache();
    }
  }

  /// 💾 Carrega trilhos guardados localmente
  Future<void> loadTrailsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      final cachedList = jsonDecode(cachedData) as List<dynamic>;
      setState(() {
        trails = List<Map<String, dynamic>>.from(cachedList);
        isOffline = true;
      });
      debugPrint("📦 ${trails.length} trilhos carregados do cache (zona ${widget.zoneId}).");
    } else {
      setState(() {
        trails = [];
        isOffline = true;
      });
      debugPrint("❌ Nenhum cache disponível para zona ${widget.zoneId}.");
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
                        return TrailCardWidget(trail, index);
                      },
                    ),
                  )
                : Center(child: Text(AppLocalizations.of(context)!.no_trails_available)),
      ),
    );
  }
}
