# AGENTS.md — WalkAlgarveApp-FE

## Purpose

Repo-specific facts for this Flutter app: map, entry points, run/test commands, and
notable patterns. Cross-repo Flutter/Dart conventions live in the
[`WalkAlgarveApp`](https://github.com/GuiFFaria/WalkAlgarveApp) mono-repo's
`standards/tech/flutter-dart.md` (composed into its `flutter-frontend` stack alongside
`standards/testing.md` and `standards/code-comments.md`) — this file holds only what's
true of this repo specifically, not shared rules.

## Map

```
lib/
├── main.dart              # entry point, MultiProvider setup
├── views/
│   ├── context/            # app-wide ChangeNotifier state (auth_provider, locale_provider)
│   ├── screens/             # one folder per screen
│   ├── components/          # reusable widgets, one folder per component
│   └── helpers/              # stateless helpers (formatting, translations, debug)
└── l10n/                      # ARB localization source files (en, pt)
```

`documentation/` — one markdown file per feature area (auth, zones, trails, the
interactive map, POIs, profile, offline support, i18n, UI components, state management,
API integration), plus `features.md` / `possible_features.md` / `12_todo_features.md` for
roadmap notes.

## Entry points

- App: `lib/main.dart`.
- Platform shells under `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` are
  generated Flutter scaffolding — rarely touched directly.

## Run / test

```bash
flutter pub get
flutter run
flutter test
flutter gen-l10n              # after editing lib/l10n/*.arb
flutter build apk --release
flutter build ios --release
```

## Notable patterns

- `API_BASE_URL` is read from `.env` via `flutter_dotenv`, and `.env` is bundled as a
  Flutter asset (`pubspec.yaml` → `flutter.assets: - .env`) rather than injected at build
  time — a real `.env` file (gitignored, copy from `.env.example`) must exist locally
  before `flutter run` or `flutter test` will work, not just an exported shell variable.
