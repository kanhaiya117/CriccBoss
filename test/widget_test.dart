import 'package:cricboss/src/data/datasources/cricket_remote_datasource.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RapidAPI fixture-style payload parses into matches', () {
    final dataSource = RapidApiCricketDataSource(Dio());
    final matches = dataSource.parseProviderMatchesForTest({
      'data': {
        'fixtures': [
          {
            'fixture_id': 42,
            'title': 'India vs Australia',
            'competition': {'title': 'World Test Championship'},
            'venue_name': 'Eden Gardens',
            'home_team': {'name': 'India'},
            'away_team': {'name': 'Australia'},
          },
        ],
      },
    }, defaultStatus: MatchStatus.upcoming);

    expect(matches, hasLength(1));
    expect(matches.single.title, 'India vs Australia');
    expect(matches.single.series, 'World Test Championship');
    expect(matches.single.status, MatchStatus.upcoming);
  });
}
