# Zones (Regions)

**Files:**
- `lib/views/screens/zones_list_screen.dart`
- `lib/views/screens/zone_details_screen.dart`
- `lib/views/components/zone_card_widget.dart`

---

## Zones List

Displays all available zones (geographic regions of Algarve):

- Fetches all zones from `GET /zones/`
- Fetches user-owned zones from `GET /user/zones/` (authenticated)
- Owned zones are sorted to the top of the list
- Non-owned zones display a **lock icon** overlay
- **Municipality filter**: popup menu to filter zones by municipality
- Supports pull-to-refresh
- Falls back to cached data when offline; shows "Offline" indicator in AppBar

---

## Zone Details

- Displays the zone's thumbnail image (with loading/error states)
- Shows localized name and description (Portuguese or English based on app locale)
- **"View Trails" button** (green) — visible only if user owns the zone → navigates to Trails List
- **"Buy Zone" button** (blue) — visible if user does not own the zone → currently shows a placeholder snackbar

---

## Zone Card Widget

Reusable card used in the zones list:

- Cached network image with gradient overlay
- Zone title and municipality label
- Lock icon if not owned by the user
- "See More" button at the bottom
- Handles both `String` and `Map` formats for municipality data
