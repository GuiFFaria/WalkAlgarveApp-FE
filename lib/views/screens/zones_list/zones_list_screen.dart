import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/helpers/connectivity_helper.dart';
import 'package:walk_algarve_app/views/helpers/zone_helper.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/components/empty_state/empty_state_widget.dart';
import 'package:walk_algarve_app/views/components/language_switch/language_switch_widget.dart';
import 'package:walk_algarve_app/views/components/offline_banner/offline_banner_widget.dart';
import 'package:walk_algarve_app/views/components/screen_header/screen_header_widget.dart';
import 'package:walk_algarve_app/views/components/square_icon_button/square_icon_button_widget.dart';
import 'package:walk_algarve_app/views/components/zone_card/zone_card_widget.dart';
import 'package:walk_algarve_app/views/screens/zones_list/municipality_filter_sheet.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class ZonesListScreen extends StatefulWidget {
  const ZonesListScreen({super.key});

  @override
  State<ZonesListScreen> createState() => _ZonesListScreenState();
}

class _ZonesListScreenState extends State<ZonesListScreen> {
  List<Map<String, dynamic>> allZones = [];

  List<int> userZones = [];
  List<String> municipios = [];

  bool isLoading = true;
  bool isOffline = false;

  String? selectedMunicipio;

  late final AuthProvider _auth;

  List<Map<String, dynamic>> get visibleZones => selectedMunicipio == null
      ? allZones
      : allZones
          .where((z) => ZoneHelper.municipality(z) == selectedMunicipio)
          .toList();

  @override
  void initState() {
    super.initState();
    // Read here, while the screen is certainly still open.
    _auth = context.read<AuthProvider>();
    loadZones();
  }

  /// 🌐 Fluxo geral de carregamento
  Future<void> loadZones() async {
    setState(() => isLoading = true);

    final hasInternet = await ConnectivityHelper.hasConnection();

    if (hasInternet) {
      await fetchZonesFromApi();
    } else {
      await loadZonesFromCache();
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// 🌍 API: Obtém todas as zonas + zonas do utilizador
  Future<void> fetchZonesFromApi() async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final zonesUrl = Uri.parse("$baseUrl/zones/");
      final userZonesUrl = Uri.parse("$baseUrl/user/zones/");

      final prefs = await SharedPreferences.getInstance();

      /// Request ZONES
      final zonesResponse = await http.get(zonesUrl);

      /// Request USER ZONES
      // If it can't be renewed, the request fails and the saved zones are kept.
      await _auth.ensureFreshToken();
      final token = prefs.getString('auth_token');
      final userZonesResponse = await http.get(
        userZonesUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      /// ---------------- ZONES ----------------
      if (zonesResponse.statusCode == 200) {
        final decoded = jsonDecode(zonesResponse.body);

        final decodedZones =
            decoded is List ? decoded : decoded["zones"] ?? [];

        allZones = decodedZones
            .map<Map<String, dynamic>>(
                (zone) => Map<String, dynamic>.from(zone))
            .toList();

        await prefs.setString('cached_zones', jsonEncode(allZones));
      }

      /// ---------------- USER ZONES ----------------
      if (userZonesResponse.statusCode == 200) {
        final decodedUserZones = jsonDecode(userZonesResponse.body);

        userZones = decodedUserZones["zones_owned"] != null
            ? List<int>.from(decodedUserZones["zones_owned"])
            : [];

        await prefs.setString(
            'cached_user_zones', jsonEncode(userZones));
      } else {
        restoreUserZones(prefs);
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

    if (cachedZones != null) {
      final decoded = jsonDecode(cachedZones);
      allZones = decoded
          .map<Map<String, dynamic>>((z) => Map<String, dynamic>.from(z))
          .toList();
    }

    restoreUserZones(prefs);

    mergeZonesWithOwnership();
    isOffline = true;
  }

  void restoreUserZones(SharedPreferences prefs) {
    final saved = prefs.getString('cached_user_zones');
    if (saved != null) userZones = List<int>.from(jsonDecode(saved));
  }

  /// 🔄 Marca zonas que o user possui
  void mergeZonesWithOwnership() {
    allZones = allZones.map((zone) {
      return {
        ...zone,
        "user_have": userZones.contains(zone["id"]),
      };
    }).toList();

    municipios = allZones
        .map(ZoneHelper.municipality)
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // A refresh keeps the filter, unless its municipality is gone.
    if (!municipios.contains(selectedMunicipio)) selectedMunicipio = null;
  }

  void openMunicipalityFilter() {
    showMunicipalityFilterSheet(
      context,
      municipalities: municipios,
      selected: selectedMunicipio,
      onSelected: (municipality) =>
          setState(() => selectedMunicipio = municipality),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No visible bar; it keeps the status bar readable in both themes.
      appBar: AppBar(toolbarHeight: 0),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return ScreenHeaderWidget(
      overline: translations.welcome,
      title: translations.zones,
      actions: [
        const LanguageSwitchWidget(),
        SquareIconButtonWidget(
          icon: Icons.filter_list,
          tooltip: translations.select_municipality,
          onPressed: openMunicipalityFilter,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final zones = visibleZones;
    final banner = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OfflineBannerWidget(message: translations.offline_zones),
    );

    if (zones.isEmpty) {
      return Column(
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: banner,
            ),
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.terrain_outlined,
              title: translations.no_zones_available,
            ),
          ),
        ],
      );
    }

    final owned = zones.where(ZoneHelper.isUnlocked).toList();
    final others = zones.where((z) => !ZoneHelper.isUnlocked(z)).toList();

    List<Widget> group(String title, List<Map<String, dynamic>> members) => [
          if (members.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final zone in members)
              ZoneCardWidget(zone, key: ValueKey(zone["id"])),
          ],
        ];

    return RefreshIndicator(
      onRefresh: loadZones,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        children: [
          if (isOffline) banner,
          ...group(translations.your_zones, owned),
          ...group(translations.other_zones, others),
        ],
      ),
    );
  }
}
