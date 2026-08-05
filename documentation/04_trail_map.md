# Trail Map & Navigation

**File:** `lib/views/screens/trail_map_screen.dart`

The most complex screen in the app. Provides an interactive map for navigating a trail in real time.

---

## Map Setup

- Uses `flutter_map` with OpenStreetMap tile layer
- Trail path rendered as a **blue polyline** from GeoJSON coordinates
- Initial camera position centered on the trail's bounding box

---

## User Location

- Uses `geolocator` to track real-time GPS position
- User represented as a **red dot** on the map
- Location updates trigger proximity checks against POIs

---

## Trail Start Confirmation

- On first load, shows a confirmation dialog asking if the user wants to start the trail
- If confirmed: starts location tracking
- If declined: map is still viewable without active tracking

---

## Header Info Chips

Fixed header at the top of the map showing:
- Distance, Duration, Trail Type, Difficulty
