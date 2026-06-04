# CricBoss

CricBoss is a Flutter Android app for live cricket scores, ball-by-ball commentary, scorecards, favorite teams, smart alerts, voice commentary, a draggable score bubble, pinned live-score notification, and small banner ads.

## Stack

- Flutter stable and Dart with null safety
- Riverpod for app state
- Dio for RapidAPI cricket data and cricket news RSS
- Hive for local settings and favorites
- Material 3 light and dark themes
- flutter_tts for English and Hindi commentary
- flutter_local_notifications and vibration for smart alerts
- flutter_overlay_window for Android score bubble
- Ads service placeholder with app-open cooldown policy. The native ad SDK is disabled in the safe APK build until device startup stability is confirmed.

## API Failover

Live cricket data uses RapidAPI Cricket Live Data:

```bash
flutter run --dart-define=RAPIDAPI_CRICKET_KEY=your_key
```

For GitHub Actions, add `RAPIDAPI_CRICKET_KEY` as a repository secret.

Cricket news uses a free RSS feed and shows the latest three cricket articles on the dashboard.

## Android

- Minimum Android version: Android 8.0, API 26
- Package id: `com.cricboss.app`
- Overlay permission is requested when the score bubble is opened.
- Android 13+ notification permission is requested at app startup.
- Native ad SDK is currently disabled for the safe APK build. Re-enable after device startup validation.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions workflow: `.github/workflows/android-apk.yml`.
