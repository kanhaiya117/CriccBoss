import 'dart:math';

import 'package:cricboss/src/domain/models/cricket_models.dart';

class MockCricketFactory {
  MockCricketFactory({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;
  final _random = Random(42);

  List<Team> get teams => const [
    Team(
      id: 'ind',
      name: 'India',
      shortName: 'IND',
      country: 'India',
      flagEmoji: '🇮🇳',
    ),
    Team(
      id: 'aus',
      name: 'Australia',
      shortName: 'AUS',
      country: 'Australia',
      flagEmoji: '🇦🇺',
    ),
    Team(
      id: 'eng',
      name: 'England',
      shortName: 'ENG',
      country: 'England',
      flagEmoji: '🏴',
    ),
    Team(
      id: 'pak',
      name: 'Pakistan',
      shortName: 'PAK',
      country: 'Pakistan',
      flagEmoji: '🇵🇰',
    ),
    Team(
      id: 'nz',
      name: 'New Zealand',
      shortName: 'NZ',
      country: 'New Zealand',
      flagEmoji: '🇳🇿',
    ),
    Team(
      id: 'sa',
      name: 'South Africa',
      shortName: 'SA',
      country: 'South Africa',
      flagEmoji: '🇿🇦',
    ),
    Team(
      id: 'mi',
      name: 'Mumbai Indians',
      shortName: 'MI',
      country: 'India',
      flagEmoji: '💙',
    ),
    Team(
      id: 'csk',
      name: 'Chennai Super Kings',
      shortName: 'CSK',
      country: 'India',
      flagEmoji: '💛',
    ),
    Team(
      id: 'rcb',
      name: 'Royal Challengers Bengaluru',
      shortName: 'RCB',
      country: 'India',
      flagEmoji: '❤️',
    ),
  ];

  List<CricketMatch> matches() {
    final t = teams;
    return [
      _match(
        'm1',
        t[0],
        t[1],
        MatchStatus.live,
        'Border-Gavaskar Trophy',
        'Narendra Modi Stadium',
        14,
        2,
      ),
      _match(
        'm2',
        t[6],
        t[7],
        MatchStatus.live,
        'Indian Premier League',
        'Wankhede Stadium',
        18,
        5,
      ),
      _match(
        'm3',
        t[2],
        t[4],
        MatchStatus.upcoming,
        'T20 Tri-Series',
        "Lord's",
        0,
        0,
        startsInHours: 7,
      ),
      _match(
        'm4',
        t[3],
        t[5],
        MatchStatus.completed,
        'ODI Championship',
        'Gaddafi Stadium',
        49,
        6,
        result: 'Pakistan won by 18 runs',
      ),
      _match(
        'm5',
        t[8],
        t[6],
        MatchStatus.upcoming,
        'Indian Premier League',
        'M. Chinnaswamy Stadium',
        0,
        0,
        startsInHours: 28,
      ),
    ];
  }

  CricketMatch _match(
    String id,
    Team a,
    Team b,
    MatchStatus status,
    String series,
    String venue,
    int over,
    int ball, {
    int startsInHours = 0,
    String? result,
  }) {
    final firstRuns = status == MatchStatus.upcoming
        ? 0
        : 86 + _random.nextInt(92);
    final secondRuns = status == MatchStatus.completed
        ? firstRuns - 18
        : 42 + _random.nextInt(76);
    final scoreList = status == MatchStatus.upcoming
        ? <InningsScore>[]
        : [
            InningsScore(
              teamId: a.id,
              runs: firstRuns,
              wickets: 3 + _random.nextInt(4),
              overs: over + ball / 10,
            ),
            if (status != MatchStatus.live || over > 16)
              InningsScore(
                teamId: b.id,
                runs: secondRuns,
                wickets: 4,
                overs: 14.2,
              ),
          ];
    return CricketMatch(
      id: id,
      title: '${a.shortName} vs ${b.shortName}',
      series: series,
      venue: venue,
      startTime: _now.add(
        Duration(hours: startsInHours == 0 ? -2 : startsInHours),
      ),
      status: status,
      teamA: a,
      teamB: b,
      scores: scoreList,
      commentary: _commentary(a, b, over),
      scorecard: _scorecard(a, b),
      players: [..._players(a), ..._players(b)],
      result: result,
      toss: '${a.name} won the toss and chose to bat',
    );
  }

  List<Player> _players(Team team) {
    final names = [
      'Arjun Mehta',
      'Kabir Singh',
      'Rohan Das',
      'Dev Patel',
      'Ayaan Khan',
      'Nikhil Rao',
      'Sam Wilson',
    ];
    return List.generate(
      7,
      (i) => Player(
        id: '${team.id}-$i',
        name: names[i],
        role: i < 4
            ? 'Batter'
            : i == 4
            ? 'All-rounder'
            : 'Bowler',
        teamId: team.id,
      ),
    );
  }

  Scorecard _scorecard(Team a, Team b) => Scorecard(
    batting: const [
      BattingLine(
        playerName: 'Arjun Mehta',
        runs: 68,
        balls: 43,
        fours: 7,
        sixes: 3,
      ),
      BattingLine(
        playerName: 'Kabir Singh',
        runs: 51,
        balls: 36,
        fours: 5,
        sixes: 2,
        outText: 'c midwicket b Wilson',
      ),
      BattingLine(
        playerName: 'Rohan Das',
        runs: 24,
        balls: 18,
        fours: 2,
        sixes: 1,
      ),
    ],
    bowling: const [
      BowlingLine(playerName: 'Sam Wilson', overs: 4, runs: 32, wickets: 2),
      BowlingLine(playerName: 'Nikhil Rao', overs: 3.4, runs: 28, wickets: 1),
      BowlingLine(playerName: 'Dev Patel', overs: 4, runs: 39, wickets: 0),
    ],
  );

  List<CommentaryEvent> _commentary(Team a, Team b, int over) {
    final now = _now;
    return [
      CommentaryEvent(
        id: 'c1',
        over: over,
        ball: 5,
        type: AlertEventType.six,
        timestamp: now,
        text: 'SIX! Launched over long-on by Arjun Mehta.',
        hindiText: 'छक्का! अर्जुन मेहता ने लॉन्ग ऑन के ऊपर से मारा।',
      ),
      CommentaryEvent(
        id: 'c2',
        over: over,
        ball: 4,
        type: AlertEventType.normal,
        timestamp: now.subtract(const Duration(seconds: 42)),
        text: 'Short of a length, tucked into the leg side for one.',
        hindiText: 'छोटी लेंथ की गेंद, लेग साइड में एक रन।',
      ),
      CommentaryEvent(
        id: 'c3',
        over: over,
        ball: 3,
        type: AlertEventType.wicket,
        timestamp: now.subtract(const Duration(minutes: 1)),
        text: 'WICKET! Sharp catch at backward point.',
        hindiText: 'विकेट! बैकवर्ड पॉइंट पर शानदार कैच।',
      ),
      CommentaryEvent(
        id: 'c4',
        over: over,
        ball: 2,
        type: AlertEventType.four,
        timestamp: now.subtract(const Duration(minutes: 2)),
        text: 'FOUR! Pierced the cover gap with perfect timing.',
        hindiText: 'चौका! कवर के बीच से बेहतरीन टाइमिंग।',
      ),
      CommentaryEvent(
        id: 'c5',
        over: over,
        ball: 1,
        type: AlertEventType.fifty,
        timestamp: now.subtract(const Duration(minutes: 3)),
        text: 'FIFTY for Kabir Singh, a calm innings under pressure.',
        hindiText: 'कबीर सिंह का अर्धशतक, दबाव में शानदार पारी।',
      ),
    ];
  }
}
