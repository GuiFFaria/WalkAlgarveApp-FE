import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

import 'package:walk_algarve_app/views/helpers/debug_helper.dart';
import 'package:walk_algarve_app/views/components/poi_info_popup.dart';

class TrailMapScreen extends StatefulWidget {
  final dynamic trail;

  const TrailMapScreen({
    super.key,
    required this.trail,
  });

  @override
  State<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends State<TrailMapScreen> {
  final MapController _mapController = MapController();

  int _currentPoiIndex = 0;
  bool _trailStarted = false;

  StreamSubscription<Position>? _positionStream;
  LatLng? _userLocation;

  dynamic _activePoi;
  bool _poiPopupVisible = false;

  static const double poiActivationRadius = 25;

  @override
  void initState() {
    super.initState();

    DebugLogger.info("TrailMap", "Inicialização da página");

    try {
      _sortPois();
    } catch (e) {
      DebugLogger.warn("TrailMap", "Erro ao ordenar POIs — ignorado");
      DebugLogger.error("TrailMap", "Sort POIs", e);
    }

    _showStartPopup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    DebugLogger.info("TrailMap", "Location stream cancelado");
    super.dispose();
  }

  void _sortPois() {
    final pois = widget.trail['properties']?['pois']?['features'];
    final path = widget.trail['geometry']?['coordinates'];

    if (pois == null || path == null || pois.isEmpty || path.isEmpty) return;

    final start = LatLng(path.first[1], path.first[0]);

    double distToStart(dynamic poi) {
      final c = poi['geometry']['coordinates'];
      return Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        c[1],
        c[0],
      );
    }

    pois.sort((a, b) => distToStart(a).compareTo(distToStart(b)));
  }

  void _showStartPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translations = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Text(
                  translations.start_trail_body,
                  textAlign: TextAlign.center,
                ),
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
    _trailStarted = true;
    await _enableLocationTracking();

    if (_userLocation != null) {
      _mapController.move(_userLocation!, 17);
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
          permission == LocationPermission.deniedForever) return;

      final pois =
          widget.trail['properties']?['pois']?['features'] as List<dynamic>?;

      if (pois == null || pois.isEmpty) return;

      _positionStream =
          Geolocator.getPositionStream().listen((Position pos) {
        final user = LatLng(pos.latitude, pos.longitude);

        setState(() => _userLocation = user);

        for (final poi in pois) {
          if (_isUserNearPoi(user, poi)) {
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

  bool _isUserNearPoi(LatLng user, dynamic poi) {
    final c = poi['geometry']['coordinates'];
    final d = Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      c[1],
      c[0],
    );
    return d <= poiActivationRadius;
  }

  List<LatLng> _extractPath() {
    final coords = widget.trail['geometry']['coordinates'];
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  List<dynamic> _extractPois() =>
      widget.trail['properties']?['pois']?['features'] ?? [];

  String _letter(int index) => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final path = _extractPath();
    final pois = _extractPois();

    int visiblePois = !_trailStarted
        ? 2
        : (_currentPoiIndex + 2).clamp(0, pois.length);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
            ),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                    path.isNotEmpty ? path.first : const LatLng(0, 0),
                initialZoom: 17,
                interactionOptions:
                    const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: path,
                      strokeWidth: 5,
                      color: const Color(0xFF4A90E2),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...List.generate(visiblePois, (i) {
                      final poi = pois[i];
                      final c = poi['geometry']['coordinates'];
                      final point = LatLng(c[1], c[0]);

                      final clickable = _userLocation != null &&
                          _isUserNearPoi(_userLocation!, poi);

                      return Marker(
                        point: point,
                        width: 26,
                        height: 26,
                        child: GestureDetector(
                          onTap: clickable
                              ? () {
                                  setState(() {
                                    _activePoi = poi;
                                    _poiPopupVisible = true;
                                  });
                                }
                              : null,
                          child: _poiMarker(_letter(i), clickable),
                        ),
                      );
                    }),
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 18,
                        height: 18,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          _buildHeader(widget.trail),

          AnimatedPositioned(
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
                      onClose: () {
                        setState(() {
                          _poiPopupVisible = false;
                          _activePoi = null;
                        });
                      },
                    ),
            ),
          ),
        ],
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic trail) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trail['properties']['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                      Icons.route, "${trail['properties']['distance_km']} km"),
                  _buildInfoChip(Icons.timer,
                      trail['properties']['duration_min'].toString()),
                  _buildInfoChip(
                      Icons.refresh, trail['properties']['trail_type']),
                  _buildInfoChip(
                      Icons.flag, trail['properties']['difficulty']),
                ],
              ),
            ],
          ),
        ),
      ),
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
