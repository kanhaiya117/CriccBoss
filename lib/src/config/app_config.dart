const bool kMockMode = true;

class AppConfig {
  const AppConfig._();

  static const appName = 'CricBoss';
  static const cricketDataBaseUrl = 'https://api.cricketdata.org/v1';
  static const cricApiBaseUrl = 'https://api.cricapi.com/v1';
  static const rapidApiCricketBaseUrl =
      'https://cricket-live-data.p.rapidapi.com';
  static const rapidApiCricketHost = 'cricket-live-data.p.rapidapi.com';
  static const cricketDataApiKey = String.fromEnvironment(
    'CRICKETDATA_API_KEY',
  );
  static const cricApiKey = String.fromEnvironment('CRICAPI_KEY');
  static const rapidApiCricketKey = String.fromEnvironment(
    'RAPIDAPI_CRICKET_KEY',
  );
  static const adOpenCooldown = Duration(hours: 12);
  static const liveRefresh = Duration(seconds: 8);
}
