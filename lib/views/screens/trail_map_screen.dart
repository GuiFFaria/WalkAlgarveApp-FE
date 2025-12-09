import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  @override
  void initState() {
    super.initState();

    /// 🔥 Ordena os POIs assim que os dados do trilho chegam
    _sortPois();

    /// 🔥 Só depois aparece o popup
    _showStartPopup();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// ===========================================================
  /// ORDENAR POIs POR ORDEM GEOGRÁFICA SEGUINDO O TRILHO
  /// ===========================================================
  void _sortPois() {
    final pois = widget.trail['properties']['pois']['features'];
    final path = widget.trail['geometry']['coordinates'];

    if (pois == null || path == null || pois.isEmpty || path.isEmpty) return;

    // Primeiro ponto do trilho
    final start = LatLng(path.first[1], path.first[0]);

    // Calcula distância ao ponto inicial
    double distToStart(dynamic poi) {
      final c = poi['geometry']['coordinates'];
      return Geolocator.distanceBetween(start.latitude, start.longitude, c[1], c[0]);
    }

    // Ordena lista
    pois.sort((a, b) => distToStart(a).compareTo(distToStart(b)));

    debugPrint("🔄 POIs ordenados com sucesso.");
  }

  /// ===========================================================
  /// POP-UP INICIAL
  /// ===========================================================
  void _showStartPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Iniciar trilho?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Deseja iniciar o percurso agora?", textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: const Text("Voltar"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        child: const Text("Iniciar"),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _startTrail();
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// ===========================================================
  /// INICIAR TRILHO
  /// ===========================================================
  Future<void> _startTrail() async {
    _trailStarted = true;
    await _enableLocationTracking();

    if (_userLocation != null) {
      _mapController.move(_userLocation!, 17);
    }
  }

  /// ===========================================================
  /// LOCALIZAÇÃO + DESBLOQUEIO DE POIs
  /// ===========================================================
  Future<void> _enableLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pois = widget.trail['properties']['pois']['features'];

      _positionStream = Geolocator.getPositionStream().listen((pos) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });

        if (_currentPoiIndex + 1 >= pois.length) return;

        final nextPoi = pois[_currentPoiIndex + 1];
        final c = nextPoi['geometry']['coordinates'];
        final nextLatLng = LatLng(c[1], c[0]);

        final d = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          nextLatLng.latitude,
          nextLatLng.longitude,
        );

        if (d < 25) {
          setState(() => _currentPoiIndex++);
        }
      });
    } catch (e) {
      debugPrint("Erro localização: $e");
    }
  }

  /// ===========================================================
  /// EXTRAÇÃO DE CAMINHO / POIs
  /// ===========================================================
  List<LatLng> _extractPath() {
    final coords = widget.trail['geometry']['coordinates'];
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  List<dynamic> _extractPois() {
    return widget.trail['properties']['pois']['features'] ?? [];
  }

  String _letter(int index) => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final path = _extractPath();
    final pois = _extractPois();

    /// POIs visíveis (antes do trilho começar mostra A e B)
    int visiblePois = !_trailStarted
        ? 2
        : (_currentPoiIndex + 2).clamp(0, pois.length);

    _userLocation = LatLng(pois[0]['geometry']['coordinates'][1], pois[0]['geometry']['coordinates'][0]);

    return Scaffold(
      body: Stack(
        children: [
          /// ============================
          /// MAPA
          /// ============================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: path.first,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all, // garante todos os gestos
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              PolylineLayer(
                polylines: [
                  Polyline(
                    points: path,
                    color: Color(0xFF4A90E2),
                    strokeWidth: 5,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  ...List.generate(
                    visiblePois,
                        (i) {
                      final poi = pois[i];
                      final c = poi['geometry']['coordinates'];
                      final pos = LatLng(c[1], c[0]);
                      return Marker(
                        point: pos,
                        width: 25,
                        height: 25,
                        child: _poiMarker(_letter(i)),
                      );
                    },
                  ),

                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 25,
                      height: 25,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          _buildHeader(widget.trail),

          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              heroTag: "loc",
              backgroundColor: Color(0xFF4A90E2),
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 17);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _poiMarker(String text) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF4A90E2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// HEADER (mantido igual ao teu original)
  Widget _buildHeader(dynamic trail) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.5, 10, 8.5, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                /// ⭐ TÍTULO + SETA NA MESMA LINHA
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        trail['properties']['name'],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// ⭐ WRAP CENTRADO
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(Icons.route,
                          "${trail['properties']['distance_km']} km"),
                      _buildInfoChip(Icons.timer,
                          trail['properties']['duration_min'].toString()),
                      _buildInfoChip(Icons.refresh,
                          trail['properties']['trail_type']),
                      _buildInfoChip(Icons.flag,
                          trail['properties']['difficulty']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }




  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Color(0xFF4A90E2)),
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
