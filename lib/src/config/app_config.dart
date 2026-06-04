class AppConfig {
  const AppConfig._();

  static const appName = 'CricBoss';
  static const rapidApiCricketBaseUrl =
      'https://cricket-live-line1.p.rapidapi.com';
  static const rapidApiCricketHost = 'cricket-live-line1.p.rapidapi.com';
  static const rapidApiCricketKey = String.fromEnvironment(
    'RAPIDAPI_CRICKET_KEY',
    defaultValue: '95a6939474mshe4a676982eba4c5p1c382ajsnf492a6fcb418',
  );
  static const adOpenCooldown = Duration(hours: 12);
  static const liveRefresh = Duration(seconds: 8);
}
