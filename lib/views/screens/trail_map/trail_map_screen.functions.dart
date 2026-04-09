import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

const double poiActivationRadius = 25;

List<LatLng> extractPath(dynamic trail) {
  final coords = trail['geometry']['coordinates'];
  return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
}

List<dynamic> extractPois(dynamic trail) =>
    trail['properties']?['pois']?['features'] ?? [];

String poiLetter(int index) => String.fromCharCode(65 + index);

bool isUserNearPoi(LatLng user, dynamic poi) {
  final c = poi['geometry']['coordinates'];
  final d = Geolocator.distanceBetween(
    user.latitude,
    user.longitude,
    c[1],
    c[0],
  );
  return d <= poiActivationRadius;
}

void sortPoisByDistanceFromStart(dynamic trail) {
  final pois = trail['properties']?['pois']?['features'];
  final path = trail['geometry']?['coordinates'];

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
