# Offline Support & Caching

**Mechanism:** `SharedPreferences` + `connectivity_plus`

---

## Connectivity Detection

Every screen that fetches remote data first checks for internet connectivity. If offline:
- Loads data from local cache
- Shows an offline banner (zones and trails list)

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
| `pending_favorites` | Favorite changes waiting to be confirmed |

Only a successful `GET /user/zones/` replaces `cached_user_zones`. When that request
doesn't succeed, even online, the zones list shows the saved ones.

Signing out removes both tokens, `user`, `cached_user_zones` and the
`cached_trails_zone_{id}` lists, which belong to the account. It happens from the Logout
button, or at startup when the API rejects the session. Being offline never signs out.

---

## Pending Favorites Sync

Handled by `lib/views/helpers/favorites_store.dart`.

1. Every change is first written to `pending_favorites` as
   `{"trail_id", "favorite", "user_id"}`; only the latest choice per trail is kept.
2. It is sent at once when online, and otherwise when a trail list is next opened or
   refreshed online, before the list is fetched.
3. `POST /trails/` only flips a favorite, so the app compares the `is_favorite` in the
   reply with the wanted state and sends once more if they differ.
4. A change is removed when the API confirms it. It stays after a lost connection, a
   server error or an unexpected reply, and while the user has to sign in again (an
   expired token is renewed first).
5. A change the API refuses (for example, a removed trail) is dropped.
6. Only the signed-in account's changes are sent and shown.

Changes queued by earlier versions have no `favorite` or `user_id`; each is sent once.
