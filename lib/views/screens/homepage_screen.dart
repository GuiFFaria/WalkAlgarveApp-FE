import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:walk_algarve_app/views/components/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/components/custom_drawer_widget.dart';
import 'package:walk_algarve_app/views/components/trail_card_widget.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  List<dynamic> trails = [];
  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    loadTrails();
  }

  /// 🔌 Verifica a conexão à internet
  Future<bool> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 🌐 Carrega os trilhos — API ou cache local
  Future<void> loadTrails() async {
    setState(() => isLoading = true);

    final hasInternet = await checkConnection();

    if (hasInternet) {
      debugPrint("✅ Online - Fetching from API...");
      await fetchTrailsFromApi();
    } else {
      debugPrint("⚠️ Offline - Loading cached data...");
      await loadTrailsFromCache();
    }

    setState(() => isLoading = false);
  }

  /// 🌍 Busca dados da API e guarda em cache
  Future<void> fetchTrailsFromApi() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse("$baseUrl/trails/");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
        final decodedTrails = decodedJson['features'] as List<dynamic>;

        setState(() {
          trails = List<Map<String, dynamic>>.from(decodedTrails);
          isOffline = false;
        });

        // 💾 Guarda localmente os dados
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_trails', jsonEncode(trails));

        debugPrint("💾 Dados guardados localmente (${trails.length} trilhos).");
      } else {
        debugPrint("Erro ao buscar trilhos: ${response.body}");
        await loadTrailsFromCache(); // fallback
      }
    } catch (e) {
      debugPrint("Erro de conexão: $e");
      await loadTrailsFromCache(); // fallback
    }
  }

  /// 💾 Carrega dados guardados localmente
  Future<void> loadTrailsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_trails');

    if (cachedData != null) {
      final cachedList = jsonDecode(cachedData) as List<dynamic>;
      setState(() {
        trails = List<Map<String, dynamic>>.from(cachedList);
        isOffline = true;
      });
      debugPrint("📦 ${trails.length} trilhos carregados do cache.");
    } else {
      setState(() {
        trails = [];
        isOffline = true;
      });
      debugPrint("❌ Nenhum dado em cache disponível.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawerWidget(),
      appBar: CustomAppBarWidget(
        title: isOffline ? "Trails (Offline)" : "Trails",
        onFilterPressed: () => debugPrint("Filtro pressionado!"),
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
                : const Center(child: Text("Nenhum trilho encontrado.")),
      ),
    );
  }
}