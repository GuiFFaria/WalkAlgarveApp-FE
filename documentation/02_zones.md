# Zones (Regions)

**Files:**
- `lib/views/screens/zones_list_screen.dart`
- `lib/views/screens/zone_details_screen.dart`
- `lib/views/components/zone_card_widget.dart`

---

## Zones List

Displays all available zones (geographic regions of Algarve):

- Fetches all zones from `GET /zones/`
- Fetches user-owned zones from `GET /user/zones/` (authenticated), after renewing a
  token that has expired or is about to
- Keeps the saved owned zones when that request doesn't succeed, including after a
  failed renewal, without signing out
- Owned zones come first under "Your zones"; the rest are under "Other zones"
- **Municipality filter**: header button that opens a bottom sheet; pull-to-refresh
  keeps the choice
- Supports pull-to-refresh
- Falls back to cached data when offline and shows an offline banner

---

## Zone Details

- Large photo with a back button over it
- Localized name (the zone's own name when untranslated) and description
- Municipality and locked/unlocked labels
- **"View Trails" button** if the user owns the zone → navigates to Trails List
- **"Buy Zone" button** otherwise → currently shows a placeholder snackbar

---

## Zone Card Widget

Reusable card used in the zones list:

- Cached network image, or a placeholder (with a lock on locked zones)
- Zone name, municipality and locked/unlocked labels
- The whole card opens Zone Details
- Handles both `String` and `Map` formats for municipality data
