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

  test('RapidAPI results payload parses completed matches', () {
    final dataSource = RapidApiCricketDataSource(Dio());
    final matches = dataSource.parseProviderMatchesForTest({
      'results': [
        {
          'id': 2879797,
          'venue': 'Green Park, Kanpur',
          'date': '2024-09-27T04:00:00+00:00',
          'status': 'Complete',
          'result': 'India won by 7 wickets',
          'match_title': 'India v Bangladesh at Green Park, Kanpur, .',
          'match_subtitle': '2nd Test',
          'home': {'id': 285, 'name': 'India', 'code': 'IND'},
          'away': {'id': 342, 'name': 'Bangladesh', 'code': 'BAN'},
        },
      ],
    }, defaultStatus: MatchStatus.completed);

    expect(matches, hasLength(1));
    expect(matches.single.title, 'India v Bangladesh at Green Park, Kanpur, .');
    expect(matches.single.teamA.shortName, 'IND');
    expect(matches.single.teamB.shortName, 'BAN');
    expect(matches.single.result, 'India won by 7 wickets');
    expect(matches.single.status, MatchStatus.completed);
  });

  test('RapidAPI live-line payload parses live scores', () {
    final dataSource = RapidApiCricketDataSource(Dio());
    final matches = dataSource.parseProviderMatchesForTest({
      'data': [
        {
          'team_a_id': 8,
          'team_a': 'Pakistan',
          'team_a_short': 'PAK',
          'team_b_id': 14,
          'team_b': 'Australia',
          'team_b_short': 'AUS',
          'team_a_scores': '41-1',
          'team_a_over': '6.2',
          'team_b_scores': '157-10',
          'team_b_over': '42.0',
          'match_id': 13259,
          'series': 'Australia tour of Pakistan 2026',
          'matchs': '3rd ODI',
          'venue': 'Gaddafi Stadium, Lahore',
          'need_run_ball': 'Pakistan NEED 117 RUNS IN 43.4 OVERS TO WIN',
          'match_status': 'Live',
        },
      ],
    });

    expect(matches, hasLength(1));
    expect(matches.single.id, '13259');
    expect(matches.single.status, MatchStatus.live);
    expect(matches.single.teamA.shortName, 'PAK');
    expect(matches.single.teamB.shortName, 'AUS');
    expect(matches.single.scores, hasLength(2));
    expect(matches.single.scoreSummary, contains('PAK 41/1'));
    expect(matches.single.latestEvent, contains('Pakistan NEED'));
  });
}
