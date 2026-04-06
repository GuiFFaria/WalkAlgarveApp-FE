import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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

  int _currentPoiIndex = 0;
  bool _trailStarted = true;

  StreamSubscription<Position>? _positionStream;
  LatLng? _userLocation;

  dynamic _activePoi;
  bool _poiPopupVisible = false;

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

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setDebugLocationNearPoiA(),
    );

    _showStartPopup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    DebugLogger.info("TrailMap", "Location stream cancelado");
    super.dispose();
  }

  // DEBUG: hardcoded location near POI A to test popup
  void _setDebugLocationNearPoiA() {
    final pois = extractPois(widget.trail);
    if (pois.isEmpty) return;
    final c = pois[0]['geometry']['coordinates'];
    // offset ~10m north so it's within the 25m activation radius
    setState(() {
      _userLocation = LatLng(c[1] + 0.00009, c[0]);
      _activePoi = pois[0];
      _poiPopupVisible = true;
    });
  }

  void _showStartPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translations = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translations.start_trail_title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pois = extractPois(widget.trail);
      if (pois.isEmpty) return;

      // DEBUG: real-time location tracking disabled while testing hardcoded location
      // _positionStream = Geolocator.getPositionStream().listen((Position pos) {
      //   final user = LatLng(pos.latitude, pos.longitude);
      //   setState(() => _userLocation = user);
      //   for (final poi in pois) {
      //     if (isUserNearPoi(user, poi)) {
      //       if (_activePoi != poi) {
      //         setState(() {
      //           _activePoi = poi;
      //           _poiPopupVisible = true;
      //         });
      //       }
      //       return;
      //     }
      //   }
      //   if (_poiPopupVisible) {
      //     setState(() {
      //       _poiPopupVisible = false;
      //       _activePoi = null;
      //     });
      //   }
      // });
    } catch (e) {
      DebugLogger.error("TrailMap", "Erro no tracking", e);
    }
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
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.walk_algarve_app',
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
      final clickable =
          _userLocation != null && isUserNearPoi(_userLocation!, poi);

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
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
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
                    Icons.route,
                    "${trail['properties']['distance_km']} km",
                  ),
                  _buildInfoChip(
                    Icons.timer,
                    trail['properties']['duration_min'].toString(),
                  ),
                  _buildInfoChip(
                    Icons.refresh,
                    trail['properties']['trail_type'],
                  ),
                  _buildInfoChip(Icons.flag, trail['properties']['difficulty']),
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
