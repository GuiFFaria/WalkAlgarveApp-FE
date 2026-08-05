# State Management

**Pattern:** Provider (ChangeNotifier)

---

## AuthProvider

Manages authentication state globally:
- Token storage, validation, refresh
- Exposed to all screens via `context.read<AuthProvider>()`

---

## LocaleProvider

Manages the current app language:
- `locale` getter returns the active `Locale`
- `toggleLocale()` switches between PT and EN
- `setLocale(Locale)` sets a specific locale

---

## MultiProvider Setup (`main.dart`)

Both providers are initialized at app root and available throughout the widget tree.
