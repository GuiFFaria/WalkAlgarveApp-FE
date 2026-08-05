# Profile

**File:** `lib/views/screens/profile_screen.dart`

---

## User Info

- Displays username and email loaded from `SharedPreferences`
- Profile picture with a camera icon for changing the photo (uses `image_picker`)
- Profile image upload to the backend is not yet implemented

---

## Statistics (Placeholder)

Three stat cards are shown but use hardcoded values:
- Favorites: 12
- Completed: 8
- Zones: 3

---

## Menu Options (Partially Implemented)

| Option | Status |
|---|---|
| Change Language | TODO |
| Change Password | TODO |
| Manage Offline Maps | TODO |
| Trail History | TODO |

---

## Logout

- Red logout button at the bottom
- Calls `AuthProvider.logout()` → clears tokens
- Navigates back to Landing Page
