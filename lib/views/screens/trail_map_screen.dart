import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class TrailMapScreen extends StatefulWidget {
  final dynamic trail; // <- Dados vindos da app

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
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _listenToUserLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// 🔥 Sistema de desbloqueio automático dos POIs
  void _listenToUserLocation() async {
    await Geolocator.requestPermission();

    _positionStream = Geolocator.getPositionStream().listen((pos) {
      final pois = widget.trail['pois'];
      if (_currentPoiIndex >= pois.length) return;

      final currentPoi = pois[_currentPoiIndex];
      final LatLng poiPos = currentPoi['position'];

      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        poiPos.latitude,
        poiPos.longitude,
      );

      if (distance < 25) {
        if (_currentPoiIndex < pois.length - 1) {
          setState(() => _currentPoiIndex++);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;

    final List<LatLng> path = List<LatLng>.from(trail['path']);
    final List<dynamic> pois = trail['pois'];

    return Scaffold(
      extendBodyBehindAppBar: true,

      /// ⭐ Header com dados do trilho
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 110,
        flexibleSpace: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trail['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.route, size: 16),
                    const SizedBox(width: 4),
                    Text("${trail['distance']} km    "),

                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text("${trail['duration']}    "),

                    const Icon(Icons.refresh, size: 16),
                    const SizedBox(width: 4),
                    Text(trail['circular'] == true ? "Circular    " : "Linear    "),

                    const Icon(Icons.flag, size: 16),
                    const SizedBox(width: 4),
                    Text(trail['difficulty']),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          /// ⭐ Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: path.first,
              initialZoom: 15,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),

              /// ⭐ Trilho marcado
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: path,
                    color: Colors.brown.shade400,
                    strokeWidth: 6,
                  ),
                ],
              ),

              /// ⭐ POIs progressivos
              MarkerLayer(
                markers: List.generate(
                  _currentPoiIndex + 1,
                  (i) {
                    final poi = pois[i];
                    final LatLng pos = poi['position'];

                    return Marker(
                      width: 45,
                      height: 45,
                      point: pos,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade400,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            poi['title'], // A, B, C...
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          /// ⭐ Botão de localização
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              heroTag: "loc",
              onPressed: () async {
                final pos = await Geolocator.getCurrentPosition();
                _mapController.move(
                  LatLng(pos.latitude, pos.longitude),
                  17,
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
