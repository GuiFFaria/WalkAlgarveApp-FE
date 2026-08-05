# Walk Algarve App

A mobile app for exploring hiking and walking trails in the Algarve region of Portugal.
Interactive trail maps, geospatial route tracking, points of interest (POIs), zone
discovery, and multi-language support (Portuguese and English).

**Stack:** Flutter 3.9+ · Dart · Provider · flutter_map · Geolocator

This app talks to the [`WalkAlgarveApp-BE`](https://github.com/GuiFFaria/WalkAlgarveApp-BE)
Django REST API, which lives in its own repo.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Flutter SDK | 3.9.2+ |
| Dart | Included with Flutter |
| Xcode | iOS builds (macOS only) |
| Android Studio / SDK | Android builds |
| CocoaPods | iOS dependency manager |

Install Flutter: https://docs.flutter.dev/get-started/install

## Setup

### 1. Configure environment variables

Create a `.env` file at the project root (see `.env.example`):

```env
API_BASE_URL=http://localhost:8000/api
```

> For a physical device, replace `localhost` with your machine's local IP (e.g.
> `http://192.168.1.x:8000/api`). For the Android emulator specifically, use
> `http://10.0.2.2:8000/api` (see `.env.example`).

### 2. Install dependencies

```bash
flutter pub get
```

### 3. iOS — install CocoaPods (macOS only)

```bash
cd ios
pod install
cd ..
```

### 4. Run the app

```bash
flutter run
```

Flutter will prompt you to select a connected device or emulator.

## Running on a physical device

1. Set `API_BASE_URL` in `.env` to your machine's local network IP:
   ```
   API_BASE_URL=http://192.168.x.x:8000/api
   ```
2. Make sure the backend's `ALLOWED_HOSTS` allows connections from your device's network
   (see `WalkAlgarveApp-BE`'s README — `ALLOWED_HOSTS = ['*']` is already set for local
   development) and that the server is bound to `0.0.0.0`, not just `localhost`.
3. Connect your device via USB or ensure it's on the same Wi-Fi network as your
   development machine.
4. Run `flutter run` and select the device.

## Building for production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS Archive

```bash
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode to archive and distribute.

---

## Project structure

```
lib/
├── main.dart                  # Entry point, MultiProvider setup
├── views/
│   ├── context/               # App-wide state (auth_provider, locale_provider)
│   ├── screens/                # One folder per screen
│   ├── components/             # Reusable widgets, one folder per component
│   └── helpers/                 # Stateless helpers (formatting, translations, debug)
└── l10n/                        # Localization (en, pt)
```

## Localization

The app supports **Portuguese** and **English**. Language files are in `lib/l10n/`. To
add a new language, add an ARB file and regenerate with:

```bash
flutter gen-l10n
```

## Documentation

Feature-level documentation lives in [`documentation/`](documentation/) — auth flow,
zones, trails, the interactive map, POIs, profile, offline support, i18n, UI components,
state management, and API integration.

---

## Troubleshooting

**Flutter map not loading:**
Check that the device has network access to `API_BASE_URL` and that the Django server is
running.

**CocoaPods issues on iOS:**
```bash
cd ios
pod deintegrate && pod install
```
