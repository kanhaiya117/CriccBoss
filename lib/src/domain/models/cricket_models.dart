enum MatchStatus { live, upcoming, completed }

enum AlertEventType { four, six, wicket, fifty, century, matchResult, normal }

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
}

class BattingLine {
  const BattingLine({
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.outText = 'not out',
  });

  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final String outText;
}

class BowlingLine {
  const BowlingLine({
    required this.playerName,
    required this.overs,
    required this.runs,
    required this.wickets,
  });

  final String playerName;
  final double overs;
  final int runs;
  final int wickets;
}

class Scorecard {
  const Scorecard({required this.batting, required this.bowling});

  final List<BattingLine> batting;
  final List<BowlingLine> bowling;
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
    );
  }
}
