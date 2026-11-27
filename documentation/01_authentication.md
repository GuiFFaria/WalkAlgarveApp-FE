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
- If the refresh can't be completed (offline, timeout, server error or unexpected reply) → keeps the session and navigates to Zones List (offline mode)
- If the API rejects the refresh token (401), or there is none → signs out
- Otherwise → navigates to Landing Page (unauthenticated)

---

## Login

- Fields: Email, Password
- Calls `POST /auth/login/` with credentials
- On success: stores the user, and the access and refresh tokens through
  `AuthProvider.setToken`
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
| `logout()` | Clears the tokens and the account's saved data |
| `_isTokenExpired(token)` | Decodes JWT payload and checks `exp` field |
| `_refreshAccessToken()` | Renews the token at startup; signs out only if the session is rejected |
| `tryRefreshAccessToken()` | Renews the token without signing out on failure |
| `ensureFreshToken()` | Renews a token that has expired or expires within a minute |
