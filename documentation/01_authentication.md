# Authentication

**Files:**
- `lib/views/screens/splash_screen.dart`
- `lib/views/screens/login_screen.dart`
- `lib/views/screens/register_screen.dart`
- `lib/views/context/auth_provider.dart`

---

## Splash Screen

On app launch, the splash screen validates the stored authentication token before routing the user:

- If a valid, non-expired access token exists → navigates to Zones List
- If the token is expired but a refresh token exists → attempts a silent refresh via `/auth/token/refresh/`
- If offline and a token exists → navigates to Zones List (offline mode)
- Otherwise → navigates to Landing Page (unauthenticated)

---

## Login

- Fields: Email, Password
- Calls `POST /auth/login/` with credentials
- On success: stores access token + refresh token in `SharedPreferences`
- On failure: displays error message from API response
- Shows loading spinner during request

---

## Register

- Fields: Username, Email, Password, Confirm Password
- Client-side validation: all fields required, passwords must match
- Requires internet connectivity (shows error if offline)
- Calls `POST /auth/register/`
- On success: redirects to Login screen

---

## Token Management (AuthProvider)

The `AuthProvider` (ChangeNotifier) manages the full JWT lifecycle:

| Method | Description |
|---|---|
| `loadToken()` | Reads tokens from SharedPreferences on startup |
| `setToken(access, refresh)` | Persists tokens locally and notifies listeners |
| `logout()` | Clears tokens from memory and SharedPreferences |
| `_isTokenExpired(token)` | Decodes JWT payload and checks `exp` field |
| `_refreshAccessToken()` | Calls refresh endpoint and updates access token |
