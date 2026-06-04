class AppConfig {
  const AppConfig._();

  static const appName = 'CricBoss';
  static const rapidApiCricketBaseUrl =
      'https://cricket-live-data.p.rapidapi.com';
  static const rapidApiCricketHost = 'cricket-live-data.p.rapidapi.com';
  static const rapidApiCricketKey = String.fromEnvironment(
    'RAPIDAPI_CRICKET_KEY',
    defaultValue: '95a6939474mshe4a676982eba4c5p1c382ajsnf492a6fcb418',
  );
  static const cricketNewsFeedUrl =
      'https://www.icccricketschedule.com/rss/news.xml';
  static const adOpenCooldown = Duration(hours: 12);
  static const liveRefresh = Duration(seconds: 8);
}
