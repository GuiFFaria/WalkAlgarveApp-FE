# UI Components

---

## Custom AppBar (`custom_appbar_widget.dart`)

- Colors from the theme (`app_theme.dart`)
- Centered title
- Left: back button on screens opened above another screen
- Right: PT/EN language toggle flags

---

## Bottom Tab Bar (`app_tab_bar_widget.dart`)

Shown by `home_screen.dart`, the screen opened after login. Screens opened from a tab
cover the bar.

| Tab | Screen |
|---|---|
| Explore | Zones list |
| Favorites | "Coming soon" |
| History | "Coming soon" |
| Profile | Profile, with an entry to Settings ("Coming soon") |

---

## Trail Card (`trail_card_widget.dart`)

Used in the trails list. Shows image, name, metadata, and a heart button with offline queueing.

---

## Zone Card (`zone_card_widget.dart`)

Used in the zones list. Shows photo, name, municipality and locked/unlocked labels.

---

## Shared pieces of the browsing screens

| Component | Use |
|---|---|
| `photo_placeholder_widget.dart` | Missing or failing photo |
| `offline_banner_widget.dart` | List shown from saved data |
| `info_chip_widget.dart`, `zone_tags_widget.dart` | Rounded labels |
| `square_icon_button_widget.dart` | Back and filter buttons |
| `empty_state_widget.dart` | Empty list |
| `language_switch_widget.dart` | PT/EN flags in headers |

---

## POI Info Popup (`poi_info_popup.dart`)

Bottom sheet with tabbed content (Fauna, Flora, Geology) and user messages.
