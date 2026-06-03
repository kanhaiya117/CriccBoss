# CricBoss

CricBoss is a Flutter Android app for live cricket scores, ball-by-ball commentary, scorecards, favorite teams, smart alerts, voice commentary, a draggable score bubble, pinned live-score notification, and small banner ads.

## Stack

- Flutter stable and Dart with null safety
- Riverpod for app state
- Dio for CricketData and CricAPI clients
- Hive for local settings and favorites
- Material 3 light and dark themes
- flutter_tts for English and Hindi commentary
- flutter_local_notifications and vibration for smart alerts
- flutter_overlay_window for Android score bubble
- google_mobile_ads with app-open cooldown and adaptive banners

## API Failover

Failover order is:

1. CricketData
2. CricAPI
3. Mock data

Mock mode is currently enabled in `lib/src/config/app_config.dart`:

```dart
const bool kMockMode = true;
```

When switching to live APIs, set `kMockMode` to `false` and pass keys:

```bash
flutter run --dart-define=CRICKETDATA_API_KEY=your_key --dart-define=CRICAPI_KEY=your_key
```

The UI never depends on empty API responses; it falls back to realistic local matches, players, commentary, scorecards, and events.

## Android

- Minimum Android version: Android 8.0, API 26
- Package id: `com.cricboss.app`
- Overlay permission is requested when the score bubble is opened.
- Android 13+ notification permission is requested at app startup.
- Test AdMob ids are included. Replace them before release.

## Build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

GitHub Actions workflow: `.github/workflows/android-apk.yml`.
