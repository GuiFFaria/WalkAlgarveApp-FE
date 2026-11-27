import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/helpers/connectivity_helper.dart';
import 'package:walk_algarve_app/views/helpers/favorites_store.dart';
import 'package:walk_algarve_app/views/helpers/trail_cache.dart';
import 'package:walk_algarve_app/views/helpers/trail_helper.dart';
import 'package:walk_algarve_app/views/helpers/zone_helper.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/context/locale_provider.dart';
import 'package:walk_algarve_app/views/components/empty_state/empty_state_widget.dart';
import 'package:walk_algarve_app/views/components/language_switch/language_switch_widget.dart';
import 'package:walk_algarve_app/views/components/offline_banner/offline_banner_widget.dart';
import 'package:walk_algarve_app/views/components/screen_header/screen_header_widget.dart';
import 'package:walk_algarve_app/views/components/square_icon_button/square_icon_button_widget.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/trail_card/trail_card_widget.dart';

class TrailsListScreen extends StatefulWidget {
  final Map<String, dynamic> zone;

  const TrailsListScreen({super.key, required this.zone});

  @override
  State<TrailsListScreen> createState() => _TrailsListScreenState();
}

class _TrailsListScreenState extends State<TrailsListScreen> {
  List<Map<String, dynamic>> trails = [];
  bool isLoading = true;
  bool isOffline = false;

  late final AuthProvider _auth;
  late final FavoritesStore _favorites;

  int get zoneId => widget.zone["id"];
  String get cacheKey => TrailCache.key(zoneId);

  @override
  void initState() {
    super.initState();
    // Built here, while the screen is certainly still open.
    _auth = context.read<AuthProvider>();
    _favorites = FavoritesStore(refreshToken: _auth.tryRefreshAccessToken);
    loadTrails();
  }

  /// 🌐 Carrega trilhos (API se online, cache se offline)
  Future<void> loadTrails() async {
    setState(() => isLoading = true);
    final hasInternet = await ConnectivityHelper.hasConnection();

    if (hasInternet) {
      // The API shows an expired token no favorites, without an error.
      final signedIn = await _auth.ensureFreshToken();
      // First, so the list already includes the changes made offline.
      if (signedIn) await _favorites.sync();
      await fetchTrailsFromApi(keepSavedFavorites: !signedIn);
    } else {
      await loadTrailsFromCache();
    }

    if (mounted) setState(() => isLoading = false);
  }

  /// 🛰️ Busca trilhos da API
  Future<void> fetchTrailsFromApi({bool keepSavedFavorites = false}) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse("$baseUrl/trails/?zone=$zoneId");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        url,
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final List<dynamic> loaded;
        if (decoded is List) {
          debugPrint("✅ Trilhos carregados da API (${decoded.length})");
          loaded = decoded;
        } else if (decoded is Map && decoded.containsKey("features")) {
          loaded = decoded["features"] as List;
        } else {
          throw Exception("Formato inesperado: ${decoded.runtimeType}");
        }
        await _showTrails(
          loaded,
          offline: false,
          favorites: keepSavedFavorites ? await _savedFavorites() : const {},
        );
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
      await _showTrails(jsonDecode(cached) as List, offline: true);
    } else {
      trails = [];
    }
  }

  Future<Map<Object?, bool>> _savedFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached == null) return const {};
    return {
      for (final trail
          in List<Map<String, dynamic>>.from(jsonDecode(cached)))
        trail["id"]: TrailHelper.isFavorite(trail),
    };
  }

  /// Shows the trails with [favorites] in place of the ones they came with, and
  /// the changes still waiting to be sent over both.
  Future<void> _showTrails(
    List<dynamic> loaded, {
    required bool offline,
    Map<Object?, bool> favorites = const {},
  }) async {
    final wanted = {...favorites, ...await _favorites.pending()};
    final list = List<Map<String, dynamic>>.from(loaded);
    for (final trail in list) {
      final favorite = wanted[trail["id"]];
      if (favorite != null) TrailHelper.setFavorite(trail, favorite);
    }

    if (!mounted) return;
    setState(() {
      trails = list;
      isOffline = offline;
    });
    await _saveTrails();
  }

  Future<void> _saveTrails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(trails));
  }

  Future<void> _markFavorite(Object? trailId, bool favorite) async {
    for (final trail in trails) {
      if (trail["id"] == trailId) TrailHelper.setFavorite(trail, favorite);
    }
    if (mounted) setState(() {});
    await _saveTrails();
  }

  Future<void> toggleFavorite(Map<String, dynamic> trail) async {
    final trailId = trail["id"];
    final favorite = !TrailHelper.isFavorite(trail);
    await _markFavorite(trailId, favorite);
    final outcome = await _favorites.setFavorite(trailId, favorite);

    // A later tap has its own answer.
    final tappedAgain = trails.any(
      (t) => t["id"] == trailId && TrailHelper.isFavorite(t) != favorite,
    );
    if (tappedAgain) return;

    if (outcome == FavoriteOutcome.rejected) {
      await _markFavorite(trailId, !favorite);
      return;
    }
    if (!mounted) return;

    final translations = AppLocalizations.of(context)!;
    final message = switch (outcome) {
      FavoriteOutcome.saved => favorite
          ? translations.favorite_added
          : translations.favorite_removed,
      FavoriteOutcome.queued => favorite
          ? translations.favorite_added_offline
          : translations.favorite_removed_offline,
      _ => translations.session_expired,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    return Scaffold(
      // No visible bar; it keeps the status bar readable in both themes.
      appBar: AppBar(toolbarHeight: 0, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeaderWidget(
              leading: SquareIconButtonWidget(
                icon: Icons.chevron_left,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
              ),
              title: translations.trails,
              subtitle: translations.zone_subtitle(
                ZoneHelper.name(widget.zone, locale),
              ),
              actions: const [LanguageSwitchWidget()],
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final banner = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OfflineBannerWidget(message: translations.offline_saved_data),
    );

    if (trails.isEmpty) {
      return Column(
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: banner,
            ),
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.hiking,
              title: translations.no_trails_available,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: loadTrails,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        children: [
          if (isOffline) banner,
          for (final trail in trails)
            TrailCardWidget(
              trail,
              key: ValueKey(trail["id"]),
              onFavoritePressed: () => toggleFavorite(trail),
            ),
        ],
      ),
    );
  }
}
