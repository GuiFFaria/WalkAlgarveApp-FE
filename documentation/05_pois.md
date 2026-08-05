# Points of Interest (POIs)

**Files:**
- `lib/views/screens/trail_map_screen.dart`
- `lib/views/components/poi_info_popup.dart`

---

## POI Markers

- POIs are fetched as part of the trail GeoJSON data
- Each POI is displayed as a labeled marker on the map (A, B, C, …)
- POIs are sorted by distance from the trail's starting point

---

## Proximity Detection

- When the user's GPS position is within **25 meters** of a POI, that POI becomes "active"
- The POI info popup slides up from the bottom of the screen automatically
- Tapping a POI marker also opens the popup

---

## POI Info Popup

A bottom sheet panel (`poi_info_popup.dart`) with three tabs:

| Tab | Content |
|---|---|
| **Fauna** | Animal species found near this POI |
| **Flora** | Plant species found near this POI |
| **Geology** | Geological features of the area |

- **Messages page**: community-submitted notes or observations at this POI
- **Page indicator dots** at the bottom showing current tab position
- Animated slide-up entrance from the bottom of the screen
