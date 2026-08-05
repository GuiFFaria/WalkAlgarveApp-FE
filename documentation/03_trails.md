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
- Syncs pending favorite toggles (queued while offline) when back online
- Pull-to-refresh support
- Offline fallback with cached data

---

## Trail Card Widget

Each trail is displayed as a card with:

- Cached network image with dark gradient overlay
- Trail name, distance (km), duration (hours), type, and difficulty
- **Heart icon** for favoriting:
  - Toggles immediately in the UI (optimistic update)
  - If online: calls `POST /trails/` with Bearer token
  - If offline: queues the action in `pending_favorites` (SharedPreferences) for later sync

---

## Trail Details

Full-screen detail view for a selected trail:

- Large header image (320px height)
- Overlapping white card starting at 280px with scrollable description
- Info row with icons for: distance, duration, trail type, difficulty, bike-friendly status
- Localized description (PT/EN)
- **Map button** (circular overlay on image) → opens Trail Map Screen
- **Back button** (top-left overlay)
