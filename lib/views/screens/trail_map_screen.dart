import 'dart:async';
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
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Serviço de localização desabilitado');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permissão de localização negada');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permissão de localização negada permanentemente');
        return;
      }

      final poisData = widget.trail['properties']['pois'];
      final List<dynamic> pois = poisData['features'] ?? [];

      _positionStream = Geolocator.getPositionStream().listen((pos) {
        if (_currentPoiIndex >= pois.length) return;

        final currentPoi = pois[_currentPoiIndex];
        final coords = currentPoi['geometry']['coordinates'];
        final LatLng poiPos = LatLng(coords[1], coords[0]);

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
    } catch (e) {
      print('Erro ao configurar localização: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;

    final List<LatLng> path = (trail['geometry']['coordinates'] as List)
        .map((c) => LatLng(c[1], c[0]))
        .toList();

    final poisData = trail['properties']['pois'];
    final List<dynamic> pois = poisData['features'] ?? [];

    return Scaffold(
      body: Stack(
        children: [
          /// ⭐ Mapa (ocupa toda a tela)
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
                markers: pois.isEmpty
                    ? []
                    : List.generate(
                        _currentPoiIndex + 1,
                        (i) {
                          final poi = pois[i];
                          final coords = poi['geometry']['coordinates'];
                          final LatLng pos = LatLng(coords[1], coords[0]);

                          return Marker(
                            width: 45,
                            height: 45,
                            point: pos,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade400,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  poi['properties']['name'],
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

          /// ⭐ Header com dados do trilho (fixo no topo)
          Positioned(
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Botão de voltar
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(height: 6),

                      /// Nome do trilho
                      Text(
                        trail['properties']['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      /// Informações do trilho (em Grid para evitar overflow)
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.route,
                            "${trail['properties']['distance_km'] ?? '-'} km",
                          ),
                          _buildInfoChip(
                            Icons.timer,
                            "${trail['properties']['duration_min'] ?? '-'} h",
                          ),
                          _buildInfoChip(
                            Icons.refresh,
                            trail['properties']['trail_type'] ?? '-',
                          ),
                          _buildInfoChip(
                            Icons.flag,
                            trail['properties']['difficulty'] ?? '-',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ⭐ Botão de localização
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              heroTag: "loc",
              backgroundColor: Colors.brown.shade400,
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition();
                  _mapController.move(
                    LatLng(pos.latitude, pos.longitude),
                    17,
                  );
                } catch (e) {
                  print('Erro ao obter localização: $e');
                }
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper para criar chips de informação
  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.brown.shade400,
        ),
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