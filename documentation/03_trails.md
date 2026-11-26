# Trails

**Files:**
- `lib/views/screens/trails_list_screen.dart`
- `lib/views/screens/trail_details_screen.dart`
- `lib/views/components/trail_card_widget.dart`

---

## Trails List

Displays all trails belonging to a specific zone:

- Fetches from `GET /trails/?zone={id}`
- Handles both plain JSON list and GeoJSON `features` array response formats
- Sends waiting favorite changes before fetching, and shows the ones still waiting
- Pull-to-refresh support
- Offline fallback with cached data and an offline banner
- Header with a back button, the zone's name and the language switch

---

## Trail Card Widget

Each trail is displayed as a card with:

- Cached network image, or a placeholder
- Trail name, distance (km), duration (hours), type, and difficulty. Missing facts are
  left out; the difficulties Easy, Moderate and Hard are translated
- **Heart button** for favoriting:
  - Toggles immediately in the UI (optimistic update) and in the saved list
  - Sends the change with `POST /trails/`, or keeps it for later (see
    [Offline Support](07_offline_support.md))
  - A change the API refuses is undone

---

## Trail Details

Full-screen detail view for a selected trail:

- Photo (300px) with a back button over it
- Scrolling panel with the name, four fact tiles (distance, duration, type, difficulty),
  a bike label (hidden when unknown) and the localized description
- **"View map" button** fixed at the bottom → opens Trail Map Screen
