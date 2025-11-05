import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:walk_algarve_app/views/components/custom_appbar_widget.dart';
import 'package:walk_algarve_app/views/components/custom_drawer_widget.dart';
import 'package:walk_algarve_app/views/components/zone_card_widget.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class ZonesListScreen extends StatefulWidget {
  const ZonesListScreen({super.key});

  @override
  State<ZonesListScreen> createState() => _ZonesListScreenState();
}

class _ZonesListScreenState extends State<ZonesListScreen> {
  List<Map<String, dynamic>> zones = [];
  List<int> userZones = [];
  bool isLoading = true;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    loadZones();
  }

  /// 🔌 Verifica conexão à internet
  Future<bool> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// 🌐 Fluxo de carregamento (online / offline)
  Future<void> loadZones() async {
    setState(() => isLoading = true);

    final hasInternet = await checkConnection();

    if (hasInternet) {
      debugPrint("✅ Online - Fetching from API...");
      await fetchZonesFromApi();
    } else {
      debugPrint("⚠️ Offline - Loading cached data...");
      await loadZonesFromCache();
    }

    setState(() => isLoading = false);
  }

  /// 🌍 API: Obtém todas as zonas + zonas do utilizador
  Future<void> fetchZonesFromApi() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final zonesUrl = Uri.parse("$baseUrl/zones/");
      final userZonesUrl = Uri.parse("$baseUrl/user/zones/");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      debugPrint("🔑 TOKEN USADO: $token");

      /// Request ZONES
      final zonesResponse = await http.get(zonesUrl);

      /// Request USER ZONES
      final userZonesResponse = await http.get(
        userZonesUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      /// ---------------- ZONES ----------------
      if (zonesResponse.statusCode == 200) {
        final decoded = jsonDecode(zonesResponse.body);

        final decodedZones = decoded is List
            ? decoded
            : decoded["zones"] ?? [];

        zones = decodedZones
            .map<Map<String, dynamic>>(
                (zone) => Map<String, dynamic>.from(zone))
            .toList();

        await prefs.setString('cached_zones', jsonEncode(zones));
        debugPrint("💾 ${zones.length} zonas guardadas localmente.");
      } else {
        debugPrint("❌ Erro ao obter zonas: ${zonesResponse.statusCode}");
      }

      /// ---------------- USER ZONES ----------------
      if (userZonesResponse.statusCode == 200) {
        final decodedUserZones = jsonDecode(userZonesResponse.body);

        userZones = decodedUserZones["zones_owned"] != null
            ? List<int>.from(decodedUserZones["zones_owned"])
            : [];

        await prefs.setString('cached_user_zones', jsonEncode(userZones));
        debugPrint("💾 ${userZones.length} zonas do utilizador guardadas localmente.");
      } else {
        debugPrint("❌ Erro ao obter zonas do user: ${userZonesResponse.statusCode}");
      }

      mergeZonesWithOwnership();
      isOffline = false;
    } catch (e) {
      debugPrint("❌ Erro de conexão: $e");
      await loadZonesFromCache();
    }
  }

  /// 💾 Carrega valores armazenados localmente
  Future<void> loadZonesFromCache() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedZones = prefs.getString('cached_zones');
    final cachedUserZones = prefs.getString('cached_user_zones');

    if (cachedZones != null) {
      final decoded = jsonDecode(cachedZones);
      zones = decoded
          .map<Map<String, dynamic>>((z) => Map<String, dynamic>.from(z))
          .toList();
    }

    if (cachedUserZones != null) {
      userZones = List<int>.from(jsonDecode(cachedUserZones));
    }

    mergeZonesWithOwnership();
    isOffline = true;

    debugPrint("📦 Zonas offline: ${zones.length}");
    debugPrint("📦 User zones offline: ${userZones.length}");
  }

  /// 🔄 Marca zonas que o user possui
  void mergeZonesWithOwnership() {
    zones = zones.map((zone) {
      final owns = userZones.contains(zone["id"]);
      return {...zone, "user_have": owns};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawerWidget(),
      appBar: CustomAppBarWidget(
        title: isOffline ? "${AppLocalizations.of(context)!.zones}(Offline)" : AppLocalizations.of(context)!.zones,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : zones.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: loadZones,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        final zone = zones[index];
                        return ZoneCardWidget(zone, index);
                      },
                    ),
                  )
                : Center(child: Text(AppLocalizations.of(context)!.no_zones_available)),
      ),
    );
  }
}
