# SOCIALFLOW — AI Campaign Wizard (Flutter)

Cross-platform port of the SOCIALFLOW live server wizard — **one Flutter codebase, three targets: Web, Android, Desktop.**

The Python/Flask backend (`server.py`) stays deployed as-is on Render/Railway and is the shared brain for every platform. This app only calls its HTTP API — your Kimi credential never ships in the client.

## What's inside

| File | Purpose |
|---|---|
| `lib/state.dart` | App state + persistence (same JSON shape as the web version, key `socialflow_v2`) |
| `lib/api.dart` | API client — **set your server URL here** |
| `lib/data.dart` | Audience/hook/pillar/idea libraries + calendar generator |
| `lib/widgets.dart` | Theme + shared widgets matching the original design |
| `lib/screens/` | The 9 wizard steps: Welcome → Brand → Competitors → Audience → Trends → Strategy → AI Studio → Calendar → Dashboard |

## 1. Connect your backend (required)

Deploy the Flask server first (see `README-HOSTING.md` in your server folder), then set the URL in **`lib/api.dart`**:

```dart
static const String baseUrl = 'https://your-app.onrender.com';
```

## 2. Generate platform boilerplate

This repo contains the shared code only. With Flutter installed (`flutter doctor` clean), run inside the project folder:

```bash
flutter create . --platforms web,android,windows,macos,linux
flutter pub get
```

This generates the `android/` and `web/` (plus desktop) folders without touching `lib/`.

### Android — add internet permission

Add this line to `android/app/src/main/AndroidManifest.xml`, just above `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

(The debug build works without it; release APK/Web need it.)

## 3. Run

```bash
# Web
flutter run -d chrome
# or release build you can host anywhere:
flutter build web

# Android (device/emulator attached, or builds APK)
flutter run
flutter build apk --release     # → build/app/outputs/flutter-apk/app-release.apk

# Desktop
flutter run -d windows    # or macos / linux
```

## Push to GitHub (JDAClanding)

This repository is already initialized with the remote configured:

```bash
git remote -v
# → https://github.com/JDAClanding/socialflow-flutter.git

# Create the empty repo "socialflow-flutter" at https://github.com/new (no README), then:
git push -u origin main
```

> ⚠️ **Never commit `kimi_config/` or any API key** — `.gitignore` already blocks it. The backend repo should stay private.

## Data compatibility

State is stored under the same key and shape as the web wizard (`socialflow_v2`), so a project started on the web version opens seamlessly in the app, and vice versa.
