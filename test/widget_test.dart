import 'package:cricboss/src/data/mock/mock_cricket_factory.dart';
import 'package:cricboss/src/data/datasources/cricket_remote_datasource.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock mode provides non-empty cricket data', () {
    final matches = MockCricketFactory().matches();
    expect(matches, isNotEmpty);
    expect(matches.first.commentary, isNotEmpty);
    expect(matches.first.players, isNotEmpty);
    expect(matches.first.scoreSummary, isNotEmpty);
  });

  test('RapidAPI fixture-style payload parses into matches', () {
    final dataSource = FailoverCricketDataSource(Dio(), MockCricketFactory());
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
