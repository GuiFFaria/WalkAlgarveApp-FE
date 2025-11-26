import 'dart:convert';
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
  List<Map<String, dynamic>> allZones = [];

  List<int> userZones = [];
  List<String> municipios = [];

  bool isLoading = true;
  bool isOffline = false;

  String? selectedMunicipio;

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

  /// 🌐 Fluxo geral de carregamento
  Future<void> loadZones() async {
    setState(() => isLoading = true);

    final hasInternet = await checkConnection();

    if (hasInternet) {
      await fetchZonesFromApi();
    } else {
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

        final decodedZones =
            decoded is List ? decoded : decoded["zones"] ?? [];

        zones = decodedZones
            .map<Map<String, dynamic>>(
                (zone) => Map<String, dynamic>.from(zone))
            .toList();

        await prefs.setString('cached_zones', jsonEncode(zones));
      }

      /// ---------------- USER ZONES ----------------
      if (userZonesResponse.statusCode == 200) {
        final decodedUserZones = jsonDecode(userZonesResponse.body);

        userZones = decodedUserZones["zones_owned"] != null
            ? List<int>.from(decodedUserZones["zones_owned"])
            : [];

        await prefs.setString(
            'cached_user_zones', jsonEncode(userZones));
      }

      mergeZonesWithOwnership();
      isOffline = false;
    } catch (e) {
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
  }

  /// 🔄 Marca zonas que o user possui + ordena
  void mergeZonesWithOwnership() {
    zones = zones.map((zone) {
      return {
        ...zone,
        "user_have": userZones.contains(zone["id"]),
      };
    }).toList();

    zones.sort((a, b) {
      return (b["user_have"] ? 1 : 0)
          .compareTo(a["user_have"] ? 1 : 0);
    });

    allZones = List.from(zones);

    extractMunicipios();
  }

  /// 📌 Extrai Municípios (String ou Map)
  void extractMunicipios() {
    municipios = zones
        .map<String>((z) {
          final municipioField = z["municipality"];

          if (municipioField == null) return "";

          if (municipioField is String) return municipioField;

          if (municipioField is Map &&
              municipioField["name"] != null) {
            return municipioField["name"];
          }

          return "";
        })
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    municipios.sort();
  }

  /// 🧹 Filtro por município
  void filterByMunicipio(String? municipio) {
    setState(() {
      selectedMunicipio = municipio;

      if (municipio == null || municipio.isEmpty) {
        zones = List.from(allZones);
        return;
      }

      zones = allZones.where((z) {
        final m = z["municipality"];

        if (m is String) return m == municipio;

        if (m is Map && m["name"] != null) {
          return m["name"] == municipio;
        }

        return false;
      }).toList();
    });
  }

  /// 📍 Popup de filtro
  void openMunicipioFilterPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.select_municipality,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              )
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(AppLocalizations.of(context)!.show_all),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: selectedMunicipio,
                    onChanged: (value) {
                      Navigator.pop(context);
                      filterByMunicipio(value);
                    },
                  ),
                ),
                const Divider(),

                ...municipios.map((municipio) {
                  return ListTile(
                    title: Text(municipio),
                    leading: Radio<String>(
                      value: municipio,
                      groupValue: selectedMunicipio,
                      onChanged: (value) {
                        Navigator.pop(context);
                        filterByMunicipio(value);
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 10),

                /// 🔘 BOTÃO FECHAR
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      /*AppLocalizations.of(context)!.close*/"Fechar",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawerWidget(),
      appBar: CustomAppBarWidget(
        title: isOffline
            ? "${AppLocalizations.of(context)!.zones} (Offline)"
            : AppLocalizations.of(context)!.zones,
      ),

      floatingActionButton: GestureDetector(
        onTap: openMunicipioFilterPopup,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4A90E2), // Azul moderno
                Color(0xFF9013FE), // Roxo vibrante
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.filter_list,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : zones.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: loadZones,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: zones.length,
                      itemBuilder: (context, index) {
                        return ZoneCardWidget(zones[index], index);
                      },
                    ),
                  )
                : Center(
                    child: Text(AppLocalizations.of(context)!
                        .no_zones_available),
                  ),
      ),
    );
  }
}
