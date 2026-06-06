enum MatchStatus { live, upcoming, completed }

enum AlertEventType {
  four,
  six,
  wicket,
  fifty,
  century,
  inningsBreak,
  partnership,
  matchResult,
  normal,
}

enum VoiceMode { importantOnly, fullCommentary, off }

enum CommentaryLanguage { english, hindi }

class Team {
  const Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.country,
    this.flagEmoji = '🏏',
  });

  final String id;
  final String name;
  final String shortName;
  final String country;
  final String flagEmoji;

  factory Team.fromMap(Map<String, dynamic> map) => Team(
    id: '${map['id']}',
    name: '${map['name'] ?? 'Unknown'}',
    shortName: '${map['shortName'] ?? map['short'] ?? 'TBD'}',
    country: '${map['country'] ?? map['name'] ?? 'Unknown'}',
    flagEmoji: '${map['flagEmoji'] ?? '🏏'}',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'shortName': shortName,
    'country': country,
    'flagEmoji': flagEmoji,
  };
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.role,
    required this.teamId,
    this.battingStyle,
    this.bowlingStyle,
  });

  final String id;
  final String name;
  final String role;
  final String teamId;
  final String? battingStyle;
  final String? bowlingStyle;

  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: '${map['id']}',
    name: '${map['name'] ?? 'Player'}',
    role: '${map['role'] ?? 'Player'}',
    teamId: '${map['teamId'] ?? ''}',
    battingStyle: map['battingStyle'] as String?,
    bowlingStyle: map['bowlingStyle'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'teamId': teamId,
    'battingStyle': battingStyle,
    'bowlingStyle': bowlingStyle,
  };
}

class InningsScore {
  const InningsScore({
    required this.teamId,
    required this.runs,
    required this.wickets,
    required this.overs,
  });

  final String teamId;
  final int runs;
  final int wickets;
  final double overs;

  String get display => '$runs/$wickets (${overs.toStringAsFixed(1)})';

  factory InningsScore.fromMap(Map<String, dynamic> map) => InningsScore(
    teamId: '${map['teamId'] ?? ''}',
    runs: map['runs'] as int? ?? 0,
    wickets: map['wickets'] as int? ?? 0,
    overs: (map['overs'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'teamId': teamId,
    'runs': runs,
    'wickets': wickets,
    'overs': overs,
  };
}

class BattingLine {
  const BattingLine({
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.outText = 'not out',
    this.teamId,
  });

  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final String outText;
  final String? teamId;

  factory BattingLine.fromMap(Map<String, dynamic> map) => BattingLine(
    playerName: '${map['playerName'] ?? 'Batter'}',
    runs: map['runs'] as int? ?? 0,
    balls: map['balls'] as int? ?? 0,
    fours: map['fours'] as int? ?? 0,
    sixes: map['sixes'] as int? ?? 0,
    outText: '${map['outText'] ?? 'not out'}',
    teamId: map['teamId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'playerName': playerName,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'outText': outText,
    'teamId': teamId,
  };
}

class BowlingLine {
  const BowlingLine({
    required this.playerName,
    required this.overs,
    required this.runs,
    required this.wickets,
    this.maidens = 0,
    this.teamId,
  });

  final String playerName;
  final double overs;
  final int runs;
  final int wickets;
  final int maidens;
  final String? teamId;

  double get economy => overs <= 0 ? 0 : runs / overs;

  factory BowlingLine.fromMap(Map<String, dynamic> map) => BowlingLine(
    playerName: '${map['playerName'] ?? 'Bowler'}',
    overs: (map['overs'] as num?)?.toDouble() ?? 0,
    runs: map['runs'] as int? ?? 0,
    wickets: map['wickets'] as int? ?? 0,
    maidens: map['maidens'] as int? ?? 0,
    teamId: map['teamId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'playerName': playerName,
    'overs': overs,
    'runs': runs,
    'wickets': wickets,
    'maidens': maidens,
    'teamId': teamId,
  };
}

class Scorecard {
  const Scorecard({required this.batting, required this.bowling});

  final List<BattingLine> batting;
  final List<BowlingLine> bowling;

  factory Scorecard.fromMap(Map<String, dynamic> map) => Scorecard(
    batting: [
      for (final item in map['batting'] as List? ?? const [])
        BattingLine.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
    bowling: [
      for (final item in map['bowling'] as List? ?? const [])
        BowlingLine.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
  );

  Map<String, dynamic> toMap() => {
    'batting': batting.map((line) => line.toMap()).toList(),
    'bowling': bowling.map((line) => line.toMap()).toList(),
  };
}

class CommentaryEvent {
  const CommentaryEvent({
    required this.id,
    required this.over,
    required this.ball,
    required this.text,
    required this.type,
    required this.timestamp,
    this.hindiText,
  });

  final String id;
  final int over;
  final int ball;
  final String text;
  final String? hindiText;
  final AlertEventType type;
  final DateTime timestamp;

  String get overLabel => '$over.$ball';
  bool get isImportant => type != AlertEventType.normal;

  factory CommentaryEvent.fromMap(Map<String, dynamic> map) => CommentaryEvent(
    id: '${map['id']}',
    over: map['over'] as int? ?? 0,
    ball: map['ball'] as int? ?? 0,
    text: '${map['text'] ?? ''}',
    hindiText: map['hindiText'] as String?,
    type: AlertEventType.values[map['type'] as int? ?? 8],
    timestamp:
        DateTime.tryParse('${map['timestamp']}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'over': over,
    'ball': ball,
    'text': text,
    'hindiText': hindiText,
    'type': type.index,
    'timestamp': timestamp.toIso8601String(),
  };
}

class CricketMatch {
  const CricketMatch({
    required this.id,
    required this.title,
    required this.series,
    required this.venue,
    required this.startTime,
    required this.status,
    required this.teamA,
    required this.teamB,
    required this.scores,
    required this.commentary,
    required this.scorecard,
    required this.players,
    this.result,
    this.toss,
    this.lastUpdated,
    this.isCached = false,
  });

  final String id;
  final String title;
  final String series;
  final String venue;
  final DateTime startTime;
  final MatchStatus status;
  final Team teamA;
  final Team teamB;
  final List<InningsScore> scores;
  final List<CommentaryEvent> commentary;
  final Scorecard scorecard;
  final List<Player> players;
  final String? result;
  final String? toss;
  final DateTime? lastUpdated;
  final bool isCached;

  bool involvesTeam(String team) {
    final value = team.toLowerCase();
    return teamA.name.toLowerCase().contains(value) ||
        teamB.name.toLowerCase().contains(value);
  }

  String get scoreSummary {
    if (scores.isEmpty) {
      return status == MatchStatus.upcoming ? 'Starts soon' : 'Score updating';
    }
    return scores
        .map((score) {
          final team = score.teamId == teamA.id
              ? teamA.shortName
              : teamB.shortName;
          return '$team ${score.display}';
        })
        .join('  |  ');
  }

  String get latestEvent => commentary.isEmpty
      ? 'Commentary will appear here.'
      : commentary.first.text;

  bool get isIpl =>
      series.toLowerCase().contains('ipl') ||
      series.toLowerCase().contains('indian premier league') ||
      teamA.id == 'mi' ||
      teamA.id == 'csk' ||
      teamA.id == 'rcb' ||
      teamB.id == 'mi' ||
      teamB.id == 'csk' ||
      teamB.id == 'rcb';

  InningsScore? scoreForTeam(String teamId) {
    for (final score in scores) {
      if (score.teamId == teamId) return score;
    }
    return null;
  }

  String scoreTextForTeam(Team team) {
    final score = scoreForTeam(team.id);
    if (score == null) {
      return status == MatchStatus.upcoming ? 'Yet to Bat' : '0/0 (Yet to Bat)';
    }
    return score.display;
  }

  double? get currentRunRate {
    final score = scores.isEmpty ? null : scores.last;
    if (score == null || score.overs <= 0) return null;
    return score.runs / score.overs;
  }

  int? get targetScore {
    if (scores.length < 2) return null;
    return scores.first.runs + 1;
  }

  double? get requiredRunRate {
    final target = targetScore;
    if (target == null || scores.length < 2) return null;
    final chasing = scores.last;
    final remainingOvers = 20 - chasing.overs;
    if (remainingOvers <= 0) return null;
    return (target - chasing.runs) / remainingOvers;
  }

  String get oversProgress {
    if (scores.isEmpty) return '0.0/20';
    return '${scores.last.overs.toStringAsFixed(1)}/20';
  }

  CricketMatch copyWith({
    String? id,
    String? title,
    String? series,
    String? venue,
    DateTime? startTime,
    MatchStatus? status,
    Team? teamA,
    Team? teamB,
    List<InningsScore>? scores,
    List<CommentaryEvent>? commentary,
    Scorecard? scorecard,
    List<Player>? players,
    String? result,
    String? toss,
    DateTime? lastUpdated,
    bool? isCached,
  }) {
    return CricketMatch(
      id: id ?? this.id,
      title: title ?? this.title,
      series: series ?? this.series,
      venue: venue ?? this.venue,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scores: scores ?? this.scores,
      commentary: commentary ?? this.commentary,
      scorecard: scorecard ?? this.scorecard,
      players: players ?? this.players,
      result: result ?? this.result,
      toss: toss ?? this.toss,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isCached: isCached ?? this.isCached,
    );
  }

  factory CricketMatch.fromMap(Map<String, dynamic> map) => CricketMatch(
    id: '${map['id']}',
    title: '${map['title'] ?? 'Cricket match'}',
    series: '${map['series'] ?? 'Cricket'}',
    venue: '${map['venue'] ?? 'Venue updating'}',
    startTime: DateTime.tryParse('${map['startTime']}') ?? DateTime.now(),
    status: MatchStatus.values[map['status'] as int? ?? 0],
    teamA: Team.fromMap(Map<String, dynamic>.from(map['teamA'] as Map)),
    teamB: Team.fromMap(Map<String, dynamic>.from(map['teamB'] as Map)),
    scores: [
      for (final item in map['scores'] as List? ?? const [])
        InningsScore.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
    commentary: [
      for (final item in map['commentary'] as List? ?? const [])
        CommentaryEvent.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
    scorecard: Scorecard.fromMap(
      Map<String, dynamic>.from(map['scorecard'] as Map? ?? const {}),
    ),
    players: [
      for (final item in map['players'] as List? ?? const [])
        Player.fromMap(Map<String, dynamic>.from(item as Map)),
    ],
    result: map['result'] as String?,
    toss: map['toss'] as String?,
    lastUpdated: DateTime.tryParse('${map['lastUpdated']}'),
    isCached: map['isCached'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'series': series,
    'venue': venue,
    'startTime': startTime.toIso8601String(),
    'status': status.index,
    'teamA': teamA.toMap(),
    'teamB': teamB.toMap(),
    'scores': scores.map((score) => score.toMap()).toList(),
    'commentary': commentary.map((event) => event.toMap()).toList(),
    'scorecard': scorecard.toMap(),
    'players': players.map((player) => player.toMap()).toList(),
    'result': result,
    'toss': toss,
    'lastUpdated': lastUpdated?.toIso8601String(),
    'isCached': isCached,
  };
}
