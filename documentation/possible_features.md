# Possible Features

> Suggested features based on the current project context — a hiking trail discovery and navigation app for the Algarve region.
> Organized by priority and implementation complexity.

---

## Table of Contents

1. [Trail Completion & History](#1-trail-completion--history)
2. [Ratings & Reviews](#2-ratings--reviews)
3. [Offline Map Tile Download](#3-offline-map-tile-download)
4. [Elevation Profile](#4-elevation-profile)
5. [Weather Integration](#5-weather-integration)
6. [Safety & Emergency Features](#6-safety--emergency-features)
7. [Trail Filters & Search](#7-trail-filters--search)
8. [Photo Sharing at POIs](#8-photo-sharing-at-pois)
9. [Trail Condition Reports](#9-trail-condition-reports)
10. [Audio Guides at POIs](#10-audio-guides-at-pois)
11. [Achievement System](#11-achievement-system)
12. [Push Notifications](#12-push-notifications)
13. [Social & Sharing](#13-social--sharing)
14. [Fitness Tracking Integration](#14-fitness-tracking-integration)
15. [Accessibility Filters](#15-accessibility-filters)

---

## 1. Trail Completion & History

**Priority:** High — directly extends existing favorites and profile infrastructure.

When a user completes a trail (reaches the end point on the map), the app records the completion. This replaces the current hardcoded stats on the profile screen.

**What to implement:**
- Detect when the user is within X meters of the trail endpoint → show a "You completed this trail!" dialog
- Store completions locally (`completed_trails` in SharedPreferences) and sync to the backend
- Show completed trails in a dedicated History screen (already in the drawer but not implemented)
- Display real stats on the Profile screen: total trails completed, total km walked, total time

**Backend needed:** `POST /trails/{id}/complete/`, `GET /user/history/`

---

## 2. Ratings & Reviews

**Priority:** High — high value for users deciding which trail to walk.

Allow users to rate trails (1–5 stars) and leave a short text review after completing one.

**What to implement:**
- After trail completion dialog, prompt the user to leave a rating/review (optional, dismissible)
- Show average rating and review count on Trail Details screen
- Dedicated reviews section on Trail Details (scrollable list of user reviews)
- Only allow one review per user per trail

**Backend needed:** `POST /trails/{id}/reviews/`, `GET /trails/{id}/reviews/`

---

## 3. Offline Map Tile Download

**Priority:** High — the app already has offline support for data, but the map itself requires internet. Critical for remote trail areas with no signal.

Pre-download map tiles for a specific trail's bounding box so the map works fully offline.

**What to implement:**
- "Download for offline use" button on Trail Details screen
- Progress indicator during tile download
- Storage management screen in Settings (list downloaded trails, show size, option to delete)
- `flutter_map` supports offline tile providers via a local tile cache — use `flutter_map_tile_caching` package

---

## 4. Elevation Profile

**Priority:** Medium — very relevant for hiking; helps users understand physical demands before starting.

Show a cross-section graph of altitude gain/loss along the trail.

**What to implement:**
- Elevation chart widget on Trail Details screen (below the description)
- X-axis: distance along trail; Y-axis: altitude in meters
- Highlight current user position on the chart while navigating
- Show total ascent (↑) and descent (↓) values alongside existing distance/duration chips
- Requires elevation data in the trail GeoJSON (z-coordinate or separate elevation array)

---

## 5. Weather Integration

**Priority:** Medium — directly relevant to whether a user should attempt a trail on a given day.

Show current and forecasted weather for the trail's geographic area.

**What to implement:**
- Weather widget on Trail Details screen: temperature, conditions, wind, precipitation
- Warning banner if conditions are unfavorable (e.g., rain, extreme heat >35°C, strong wind)
- Use a free API such as Open-Meteo (no API key required) with the trail's GPS coordinates
- Cache weather data for 1 hour to avoid excessive requests

---

## 6. Safety & Emergency Features

**Priority:** Medium — especially important for solo hikers in remote areas.

**What to implement:**

**Emergency contact:**
- Settings option to store an emergency contact (name + phone number)
- "Send SOS" button accessible from the Trail Map screen (e.g., long press on a dedicated button)
- Sends the user's current GPS coordinates via SMS to the stored contact

**Trail sharing (live location):**
- "Share my location" button on Trail Map — generates a link or sends a message with real-time GPS updates to a contact
- Auto-alert if the user has been stationary for too long in a remote area (configurable timeout)

**First aid info:**
- Static screen with basic first aid guidelines for common hiking incidents (blisters, heat exhaustion, snake bites)
- Accessible offline

---

## 7. Trail Filters & Search

**Priority:** Medium — the app currently has a municipality filter on zones but no filtering on trails themselves.

**What to implement:**
- Search bar on the Trails List screen (filter by name)
- Filter panel (bottom sheet) with options:
  - Difficulty: Easy / Medium / Hard
  - Distance range: slider (e.g., 0–30 km)
  - Duration range: slider
  - Trail type: circular / linear
  - Bike-friendly: yes/no
  - Dog-friendly: yes/no (requires backend field)
- Sort options: distance (shortest first), duration, difficulty, rating

---

## 8. Photo Sharing at POIs

**Priority:** Medium — turns POIs into community-driven content; builds on the existing POI messages tab.

Allow users to upload photos taken at a POI, visible to all users.

**What to implement:**
- Camera/gallery button inside the POI info popup
- Photo gallery tab (4th tab alongside Fauna, Flora, Geology)
- Photos displayed in a grid with upload date and username
- Moderation flag button ("Report photo")
- Uses existing `image_picker` package already in the project

**Backend needed:** `POST /pois/{id}/photos/`, `GET /pois/{id}/photos/`

---

## 9. Trail Condition Reports

**Priority:** Medium — high practical value; keeps trail info current without relying solely on admins.

Users who recently completed a trail can report the current conditions.

**What to implement:**
- "Report condition" button on Trail Details and Trail Map screens
- Quick report form: condition tags (e.g., "Muddy", "Overgrown", "Good condition", "Obstacle on path"), optional photo, optional text note
- Condition summary badge on Trail Card (e.g., green dot = good, orange = caution, red = issue reported)
- Reports older than 30 days automatically marked as stale

**Backend needed:** `POST /trails/{id}/conditions/`, `GET /trails/{id}/conditions/`

---

## 10. Audio Guides at POIs

**Priority:** Low-Medium — significant value for nature tourism; differentiates the app.

Play an audio narration when a user arrives at a POI, describing the fauna, flora, or geology of that point.

**What to implement:**
- Audio player widget inside the POI info popup
- Play/pause/stop controls
- Audio files stored per POI per language (PT and EN)
- Files can be pre-downloaded with the trail for offline use
- Requires `just_audio` or `audioplayers` Flutter package

**Backend needed:** audio file URLs per POI per language in the GeoJSON response

---

## 11. Achievement System

**Priority:** Low-Medium — adds gamification and long-term retention.

Reward users with badges for reaching milestones.

**Example achievements:**
| Badge | Condition |
|---|---|
| First Steps | Complete your first trail |
| Explorer | Complete trails in 3 different zones |
| Marathoner | Walk a cumulative 42 km |
| Dawn Hiker | Start a trail before 7:00 AM |
| All-terrain | Complete one trail of each difficulty level |
| Naturalist | Visit 20 different POIs |

**What to implement:**
- Achievements screen accessible from the Profile or Drawer
- Badge grid with locked/unlocked state
- Unlock animation when a badge is earned
- Progress indicators for partially completed achievements
- Push notification when a badge is unlocked

---

## 12. Push Notifications

**Priority:** Low-Medium — useful for re-engagement and time-sensitive information.

**Notification types:**
- New trail added to a zone the user owns
- Trail condition report on a favorited trail
- Seasonal trail closure warning
- Achievement unlocked
- Weekly summary: "You walked X km this week"

**What to implement:**
- Use `firebase_messaging` (FCM) for push delivery
- Notification preferences screen in Settings (toggle each type on/off)
- Deep links from notifications directly to the relevant screen

---

## 13. Social & Sharing

**Priority:** Low — nice-to-have; depends on community size.

**What to implement:**

**Trail sharing:**
- Share button on Trail Details → generates a deep link that opens the app (or a web preview) to that trail
- Share to WhatsApp, Instagram Stories, etc. via `share_plus` package

**Follow system:**
- Follow other users and see their completed trails and reviews in a feed
- "Friends also completed this trail" section on Trail Details

---

## 14. Fitness Tracking Integration

**Priority:** Low — adds value for fitness-oriented users.

**What to implement:**
- At the end of a trail, save the workout (distance, duration, elevation gain, estimated calories) to:
  - Apple Health (iOS) via `health` Flutter package
  - Google Fit (Android)
- Show estimated calories burned on the trail completion screen (based on distance + weight, weight stored optionally in profile)

---

## 15. Accessibility Filters

**Priority:** Low — broadens the target audience significantly.

**What to implement:**
- Accessibility tags on trails: wheelchair accessible, pram-friendly, suitable for mobility aids
- Filter option in the Trail Filters panel
- Accessibility icon on Trail Cards and Trail Details for quick identification
- Requires backend support for these fields per trail
