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

  test('RapidAPI upcoming payload parses every returned fixture', () {
    final dataSource = RapidApiCricketDataSource(Dio());
    final fixtures = List.generate(
      80,
      (index) => {
        'match_id': index,
        'team_a_id': index * 2,
        'team_a': index == 79 ? 'India' : 'Team $index A',
        'team_a_short': index == 79 ? 'IND' : 'T${index}A',
        'team_b_id': index * 2 + 1,
        'team_b': 'Team $index B',
        'team_b_short': 'T${index}B',
        'match_status': 'Upcoming',
        'date_wise': '07 Jun 2026, Sunday',
        'match_time': '07:30 PM',
      },
    );

    final matches = dataSource.parseProviderMatchesForTest({
      'data': fixtures,
    }, defaultStatus: MatchStatus.upcoming);

    expect(matches, hasLength(80));
    expect(matches.last.teamA.name, 'India');
    expect(matches.last.status, MatchStatus.upcoming);
  });

  test('RapidAPI Finished status parses as a completed result', () {
    final dataSource = RapidApiCricketDataSource(Dio());
    final matches = dataSource.parseProviderMatchesForTest({
      'data': [
        {
          'match_id': 13413,
          'team_a_id': 846,
          'team_a': 'Bharat Rangers',
          'team_a_short': 'BR',
          'team_b_id': 845,
          'team_b': 'India Warriors',
          'team_b_short': 'IW',
          'match_status': 'Finished',
          'result': 'Bharat Rangers won by 7 wickets',
          'date_wise': '05 Jun 2026, Friday',
        },
      ],
    }, defaultStatus: MatchStatus.completed);

    expect(matches, hasLength(1));
    expect(matches.single.status, MatchStatus.completed);
    expect(matches.single.result, 'Bharat Rangers won by 7 wickets');
  });

  test('match cache serialization preserves detail data', () {
    final match = CricketMatch(
      id: '42',
      title: 'India v Australia',
      series: 'Test Series',
      venue: 'Melbourne',
      startTime: DateTime.utc(2026, 6, 6),
      status: MatchStatus.live,
      teamA: const Team(
        id: '1',
        name: 'India',
        shortName: 'IND',
        country: 'India',
      ),
      teamB: const Team(
        id: '2',
        name: 'Australia',
        shortName: 'AUS',
        country: 'Australia',
      ),
      scores: const [
        InningsScore(teamId: '1', runs: 120, wickets: 2, overs: 20),
      ],
      commentary: [
        CommentaryEvent(
          id: 'event-1',
          over: 19,
          ball: 6,
          text: 'Four',
          type: AlertEventType.four,
          timestamp: DateTime.utc(2026, 6, 6, 12),
        ),
      ],
      scorecard: const Scorecard(
        batting: [
          BattingLine(
            playerName: 'Virat Kohli',
            runs: 75,
            balls: 42,
            fours: 9,
            sixes: 3,
            teamId: '1',
          ),
        ],
        bowling: [],
      ),
      players: const [
        Player(
          id: 'p1',
          name: 'Virat Kohli',
          role: 'Batsman',
          teamId: '1',
          battingStyle: 'Right Hand Batting',
        ),
      ],
      lastUpdated: DateTime.utc(2026, 6, 6, 12),
    );

    final restored = CricketMatch.fromMap(match.toMap());

    expect(restored.id, match.id);
    expect(restored.scorecard.batting.single.teamId, '1');
    expect(restored.players.single.battingStyle, 'Right Hand Batting');
    expect(restored.commentary.single.type, AlertEventType.four);
    expect(restored.lastUpdated, match.lastUpdated);
  });
}
