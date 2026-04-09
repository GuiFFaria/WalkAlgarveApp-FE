import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';
import 'package:walk_algarve_app/views/components/poi_info_popup/poi_info_popup.dart';
import 'package:walk_algarve_app/views/helpers/debug_helper.dart';
import 'trail_map_screen.functions.dart';

class TrailMapScreen extends StatefulWidget {
  final dynamic trail;

  const TrailMapScreen({super.key, required this.trail});

  @override
  State<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends State<TrailMapScreen> {
  final MapController _mapController = MapController();

  final int _currentPoiIndex = 0;
  bool _trailStarted = false;

  StreamSubscription<Position>? _positionStream;
  LatLng? _userLocation;
  LatLng? _lastKnownPosition;

  dynamic _activePoi;
  bool _poiPopupVisible = false;

  // Progress tracking
  DateTime? _trailStartedAt;
  double _distanceCoveredKm = 0;
  final Set<int> _visitedPoiIds = {};
  int? _activeHistoryId;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    DebugLogger.info("TrailMap", "Inicialização da página");

    try {
      sortPoisByDistanceFromStart(widget.trail);
    } catch (e) {
      DebugLogger.warn("TrailMap", "Erro ao ordenar POIs — ignorado");
      DebugLogger.error("TrailMap", "Sort POIs", e);
    }

    _showStartPopup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _elapsedTimer?.cancel();
    DebugLogger.info("TrailMap", "Location stream cancelado");
    super.dispose();
  }

  void _showStartPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translations = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translations.start_trail_title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(translations.start_trail_body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(translations.back),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _startTrail();
                      },
                      child: Text(translations.start),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _startTrail() async {
    setState(() {
      _trailStarted = true;
      _trailStartedAt = DateTime.now();
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_trailStartedAt != null) {
        setState(() => _elapsed = DateTime.now().difference(_trailStartedAt!));
      }
    });

    await _postHistoryStart();
    await _enableLocationTracking();

    if (_userLocation != null) {
      _mapController.move(_userLocation!, 17);
    }
  }

  Future<void> _postHistoryStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user');
      if (token == null || userJson == null) return;

      final userId = jsonDecode(userJson)['id'];
      final trailId = widget.trail['properties']?['id'];
      if (userId == null || trailId == null) return;

      final baseUrl = dotenv.env['API_BASE_URL']!;
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/history/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'user': userId, 'trail': trailId}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() => _activeHistoryId = data['id']);
        DebugLogger.info("TrailMap", "History criado: $_activeHistoryId");
      }
    } catch (e) {
      DebugLogger.error("TrailMap", "Erro ao criar history", e);
    }
  }

  Future<void> _enableLocationTracking() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pois = extractPois(widget.trail);
      if (pois.isEmpty) return;

      _positionStream = Geolocator.getPositionStream().listen((Position pos) {
        final user = LatLng(pos.latitude, pos.longitude);

        if (_lastKnownPosition != null) {
          final meters = Geolocator.distanceBetween(
            _lastKnownPosition!.latitude,
            _lastKnownPosition!.longitude,
            user.latitude,
            user.longitude,
          );
          setState(() => _distanceCoveredKm += meters / 1000);
        }

        setState(() {
          _userLocation = user;
          _lastKnownPosition = user;
        });

        for (final poi in pois) {
          if (isUserNearPoi(user, poi)) {
            final poiId = poi['properties']?['id'];
            if (poiId != null) _visitedPoiIds.add(poiId);

            if (_activePoi != poi) {
              setState(() {
                _activePoi = poi;
                _poiPopupVisible = true;
              });
            }
            return;
          }
        }

        if (_poiPopupVisible) {
          setState(() {
            _poiPopupVisible = false;
            _activePoi = null;
          });
        }
      });
    } catch (e) {
      DebugLogger.error("TrailMap", "Erro no tracking", e);
    }
  }

  void _showFinishDialog() {
    final translations = AppLocalizations.of(context)!;
    int selectedRating = 0;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translations.finish_trail_title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(translations.finish_trail_body),
                const SizedBox(height: 20),
                Text(
                  translations.finish_trail_rating,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF4A261),
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => selectedRating = star),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: translations.finish_trail_notes_hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(translations.back),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _finishTrail(
                          rating: selectedRating > 0 ? selectedRating : null,
                          notes: notesController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1BA6A1),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(translations.finish),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishTrail({int? rating, String notes = ''}) async {
    await _positionStream?.cancel();
    _elapsedTimer?.cancel();

    final endedAt = DateTime.now();
    final durationMin = _trailStartedAt != null
        ? endedAt.difference(_trailStartedAt!).inMinutes
        : null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user');
      if (token == null || userJson == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final userId = jsonDecode(userJson)['id'];
      final baseUrl = dotenv.env['API_BASE_URL']!;

      if (_activeHistoryId != null) {
        await http.patch(
          Uri.parse('$baseUrl/users/$userId/history/$_activeHistoryId/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'ended_at': endedAt.toIso8601String(),
            'duration_actual_min': durationMin,
            'distance_actual_km': double.parse(_distanceCoveredKm.toStringAsFixed(3)),
            'pois_visited': _visitedPoiIds.toList(),
            'completed': true,
            if (rating != null) 'rating': rating,
            if (notes.isNotEmpty) 'notes': notes,
          }),
        );
        DebugLogger.info("TrailMap", "History $_activeHistoryId terminado");
      }
    } catch (e) {
      DebugLogger.error("TrailMap", "Erro ao terminar trail", e);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final path = extractPath(widget.trail);
    final pois = extractPois(widget.trail);
    final visiblePois = !_trailStarted
        ? 2
        : (_currentPoiIndex + 2).clamp(0, pois.length);

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(path, pois, visiblePois),
          _buildHeader(widget.trail),
          if (_trailStarted) _buildFinishButton(),
          _buildPoiPopup(),
        ],
      ),
    );
  }

  Widget _buildMap(List<LatLng> path, List<dynamic> pois, int visiblePois) {
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: path.isNotEmpty ? path.first : const LatLng(0, 0),
          initialZoom: 17,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.walk_algarve_app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(points: path, strokeWidth: 5, color: const Color(0xFF4A90E2)),
            ],
          ),
          MarkerLayer(
            markers: [
              ..._buildPoiMarkers(pois, visiblePois),
              if (_userLocation != null) _buildUserMarker(),
            ],
          ),
        ],
      ),
    );
  }

  List<Marker> _buildPoiMarkers(List<dynamic> pois, int visiblePois) {
    return List.generate(visiblePois, (i) {
      final poi = pois[i];
      final c = poi['geometry']['coordinates'];
      final point = LatLng(c[1], c[0]);
      final clickable = _userLocation != null && isUserNearPoi(_userLocation!, poi);

      return Marker(
        point: point,
        width: 26,
        height: 26,
        child: GestureDetector(
          onTap: clickable
              ? () => setState(() {
                    _activePoi = poi;
                    _poiPopupVisible = true;
                  })
              : null,
          child: _poiMarker(poiLetter(i), clickable),
        ),
      );
    });
  }

  Marker _buildUserMarker() {
    return Marker(
      point: _userLocation!,
      width: 18,
      height: 18,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPoiPopup() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: _poiPopupVisible ? 0 : -380,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _poiPopupVisible ? 1 : 0,
        child: _activePoi == null
            ? const SizedBox.shrink()
            : PoiInfoPopup(
                poi: _activePoi,
                onClose: () => setState(() {
                  _poiPopupVisible = false;
                  _activePoi = null;
                }),
              ),
      ),
    );
  }

  Widget _buildFinishButton() {
    final translations = AppLocalizations.of(context)!;
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: ElevatedButton.icon(
        onPressed: _showFinishDialog,
        icon: const Icon(Icons.flag_rounded),
        label: Text(translations.finish_trail_button),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1BA6A1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _poiMarker(String text, bool active) {
    return Container(
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4A90E2) : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Widget _buildHeader(dynamic trail) {
    final totalKm = (trail['properties']['distance_km'] as num?)?.toDouble() ?? 0;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _trailStarted ? _buildProgressCard(totalKm) : _buildTrailInfo(trail),
        ),
      ),
    );
  }

  Widget _buildTrailInfo(dynamic trail) {
    return Column(
      children: [
        Text(
          trail['properties']['name'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildInfoChip(Icons.route, "${trail['properties']['distance_km']} km"),
            _buildInfoChip(Icons.timer, trail['properties']['duration_min'].toString()),
            _buildInfoChip(Icons.refresh, trail['properties']['trail_type']),
            _buildInfoChip(Icons.flag, trail['properties']['difficulty']),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(double totalKm) {
    final progress = totalKm > 0 ? (_distanceCoveredKm / totalKm).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT PROGRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_distanceCoveredKm.toStringAsFixed(1)}km',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1BA6A1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'of ${totalKm.toStringAsFixed(1)}km',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1BA6A1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TIME ELAPSED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatElapsed(_elapsed),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A90E2),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4A90E2)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
