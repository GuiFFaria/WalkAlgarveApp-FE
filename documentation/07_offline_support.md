# Offline Support & Caching

**Mechanism:** `SharedPreferences` + `connectivity_plus`

---

## Connectivity Detection

Every screen that fetches remote data first checks for internet connectivity. If offline:
- Loads data from local cache
- Shows an **"Offline"** indicator in the AppBar title

---

## Cache Keys

| Key | Content |
|---|---|
| `auth_token` | JWT access token |
| `refresh_token` | JWT refresh token |
| `user` | User object (JSON) |
| `cached_zones` | All zones list |
| `cached_user_zones` | List of zone IDs owned by the user |
| `cached_trails_zone_{id}` | Trails for a specific zone |
| `pending_favorites` | Queued favorite toggles (offline actions) |

---

## Pending Favorites Sync

When the user favorites/unfavorites a trail while offline:
1. The action is stored in `pending_favorites` (list of trail IDs + action type)
2. On the next app open or manual refresh while online, the queue is flushed and each action is sent to the API
