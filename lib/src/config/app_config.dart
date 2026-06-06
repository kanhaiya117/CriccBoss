class AppConfig {
  const AppConfig._();

  static const appName = 'CricBoss';
  static const rapidApiCricketBaseUrl =
      'https://cricket-live-line1.p.rapidapi.com';
  static const rapidApiCricketHost = 'cricket-live-line1.p.rapidapi.com';
  static const _fallbackRapidApiCricketKey =
      '95a6939474mshe4a676982eba4c5p1c382ajsnf492a6fcb418';
  static const _envRapidApiCricketKey = String.fromEnvironment(
    'RAPIDAPI_CRICKET_KEY',
    defaultValue: _fallbackRapidApiCricketKey,
  );
  static String get rapidApiCricketKey => _envRapidApiCricketKey.trim().isEmpty
      ? _fallbackRapidApiCricketKey
      : _envRapidApiCricketKey;
  static const adOpenCooldown = Duration(hours: 12);
  static const liveRefresh = Duration(seconds: 30);
  static const matchRefresh = Duration(seconds: 20);
  static const upcomingMatchesCache = Duration(minutes: 15);
  static const recentMatchesCache = Duration(minutes: 5);
  static const matchInfoCache = Duration(minutes: 10);
  static const squadCache = Duration(minutes: 30);
  static const liveDetailCache = Duration(seconds: 20);
  static const scorecardCache = Duration(minutes: 2);
}
