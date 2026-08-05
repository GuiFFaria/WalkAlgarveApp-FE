# UI Components

---

## Custom AppBar (`custom_appbar_widget.dart`)

- Teal background (`#1BA6A1`)
- Centered title
- Left: hamburger icon to open drawer
- Right: PT/EN language toggle flags

---

## Custom Drawer (`custom_drawer_widget.dart`)

Side navigation drawer with:

**Header:**
- User avatar, username, welcome message
- Gradient teal background

**Navigation Sections:**

| Section | Items |
|---|---|
| Explore | Zones, History |
| Account | Profile, Favorites |
| Settings | Settings |

**Footer:**
- App version (v1.0.0) + hiking icon

---

## Trail Card (`trail_card_widget.dart`)

Used in the trails list. Shows image, name, metadata, and a heart button with offline queueing.

---

## Zone Card (`zone_card_widget.dart`)

Used in the zones list. Shows image, name, municipality, lock icon, and a "See More" button.

---

## POI Info Popup (`poi_info_popup.dart`)

Bottom sheet with tabbed content (Fauna, Flora, Geology) and user messages.
