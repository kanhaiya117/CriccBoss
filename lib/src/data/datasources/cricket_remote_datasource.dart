import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class CricketDataSource {
  Future<List<CricketMatch>> getMatches();
  Future<CricketMatch> getMatch(String id);
  bool get usedStaleCache;
  DateTime? get lastSuccessfulUpdate;
}

class RapidApiCricketDataSource implements CricketDataSource {
  RapidApiCricketDataSource(this._dio);

  final Dio _dio;
  final Map<String, _CacheEntry<dynamic>> _cache = {};
  bool _usedStaleCache = false;
  DateTime? _lastSuccessfulUpdate;

  @override
  bool get usedStaleCache => _usedStaleCache;

  @override
  DateTime? get lastSuccessfulUpdate => _lastSuccessfulUpdate;

  @override
  Future<List<CricketMatch>> getMatches() async {
    final rapidApi = await _tryRapidApiCricket(resetState: true);
    if (rapidApi.isNotEmpty) return rapidApi;
    return const [];
  }

  @override
  Future<CricketMatch> getMatch(String id) async {
    _resetRequestState();
    if (id.startsWith('series-')) {
      final matches = await getMatches();
      return matches.firstWhere(
        (match) => match.id == id,
        orElse: () => throw StateError('Match not found'),
      );
    }
    final listMatch = await _findMatchFromList(id);
    final detail = await _getRapidApi(
      '/match/$id',
      ttl: AppConfig.matchInfoCache,
    );
    final scorecard = await _getRapidApi(
      '/match/$id/scorecard',
      ttl: AppConfig.scorecardCache,
    );
    final commentary = await _getRapidApi(
      '/match/$id/commentary',
      ttl: AppConfig.liveDetailCache,
    );
    final playingXi = await _getRapidApi(
      '/match/$id/playingXI',
      ttl: AppConfig.squadCache,
    );
    final squads = await _getRapidApi(
      '/match/$id/squads',
      ttl: AppConfig.squadCache,
    );
    final match = _parseLineMatch(
      _payloadData(detail),
      defaultStatus: MatchStatus.live,
    );
    final baseMatch = _mergeListMatch(match, listMatch);
    if (baseMatch != null) {
      return _enrichMatch(
        baseMatch,
        scorecard: scorecard,
        commentary: commentary,
        players: playingXi,
        fallbackPlayers: squads,
      );
    }
    throw StateError('Match not found');
  }

  Future<List<CricketMatch>> _tryRapidApiCricket({
    required bool resetState,
  }) async {
    if (resetState) _resetRequestState();
    if (AppConfig.rapidApiCricketKey.isEmpty) return const [];
    final parsed = <CricketMatch>[
      ..._parseLineMatches(
        await _getRapidApi('/liveMatches', ttl: AppConfig.liveDetailCache),
        defaultStatus: MatchStatus.live,
      ),
      ..._parseLineMatches(
        await _getRapidApi(
          '/upcomingMatches',
          ttl: AppConfig.upcomingMatchesCache,
        ),
        defaultStatus: MatchStatus.upcoming,
      ),
      ..._parseLineMatches(
        await _getRapidApi('/recentMatches', ttl: AppConfig.recentMatchesCache),
        defaultStatus: MatchStatus.completed,
      ),
    ];
    return _dedupeMatches(parsed);
  }

  Future<dynamic> _getRapidApi(String path, {Duration? ttl}) async {
    final cached = _cache[path];
    final now = DateTime.now();
    if (ttl != null &&
        cached != null &&
        now.difference(cached.createdAt) < ttl) {
      return cached.value;
    }
    try {
      final response = await _dio.get(
        '${AppConfig.rapidApiCricketBaseUrl}$path',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-rapidapi-host': AppConfig.rapidApiCricketHost,
            'x-rapidapi-key': AppConfig.rapidApiCricketKey,
          },
        ),
      );
      _cache[path] = _CacheEntry(response.data, now);
      _lastSuccessfulUpdate = now;
      return response.data;
    } catch (error) {
      if (cached != null) {
        _usedStaleCache = true;
        return cached.value;
      }
      return null;
    }
  }

  Future<CricketMatch?> _findMatchFromList(String id) async {
    final matches = await _tryRapidApiCricket(resetState: false);
    for (final match in matches) {
      if (match.id == id) return match;
    }
    return null;
  }

  void _resetRequestState() {
    _usedStaleCache = false;
  }

  CricketMatch? _mergeListMatch(CricketMatch? detail, CricketMatch? list) {
    if (detail == null) return list;
    if (list == null) return detail;
    return detail.copyWith(
      scores: detail.scores.isEmpty ? list.scores : detail.scores,
      commentary: detail.commentary.isEmpty
          ? list.commentary
          : detail.commentary,
      result: detail.result ?? list.result,
    );
  }

  @visibleForTesting
  List<CricketMatch> parseProviderMatchesForTest(
    dynamic payload, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    return _dedupeMatches([
      ..._parseLineMatches(payload, defaultStatus: defaultStatus),
      ..._parseMatches(payload, defaultStatus: defaultStatus),
    ]);
  }

  List<CricketMatch> _parseLineMatches(
    dynamic payload, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    final items = _extractItems(payload);
    if (items is! List || items.isEmpty) return const [];
    return items
        .map(
          (item) => item is Map
              ? _parseLineMatch(item, defaultStatus: defaultStatus)
              : null,
        )
        .whereType<CricketMatch>()
        .toList();
  }

  CricketMatch? _parseLineMatch(
    dynamic value, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    if (value is! Map) return null;
    if (!value.containsKey('team_a') ||
        !value.containsKey('team_b') ||
        !value.containsKey('match_id')) {
      return null;
    }
    final title = '${value['matchs'] ?? value['match_title'] ?? 'Match'}';
    final teamA = Team(
      id: '${value['team_a_id'] ?? value['team_a'] ?? 'team-a'}',
      name: '${value['team_a'] ?? 'Team A'}',
      shortName: '${value['team_a_short'] ?? 'TMA'}',
      country: '${value['team_a'] ?? 'Team A'}',
    );
    final teamB = Team(
      id: '${value['team_b_id'] ?? value['team_b'] ?? 'team-b'}',
      name: '${value['team_b'] ?? 'Team B'}',
      shortName: '${value['team_b_short'] ?? 'TMB'}',
      country: '${value['team_b'] ?? 'Team B'}',
    );
    final status = _lineStatus(value['match_status'], defaultStatus);
    final scores = <InningsScore>[
      ?_scoreFromLine(value, teamA, 'team_a'),
      ?_scoreFromLine(value, teamB, 'team_b'),
    ];
    final result = '${value['result'] ?? ''}'.trim();
    return _emptyMatch('${value['match_id'] ?? title.hashCode}').copyWith(
      id: '${value['match_id'] ?? title.hashCode}',
      title: '${teamA.name} v ${teamB.name} - $title',
      series: '${value['series'] ?? value['series_type'] ?? 'Cricket'}',
      venue: '${value['venue'] ?? 'Venue updating'}',
      startTime: _parseLineDate(value['date_wise'], value['match_time']),
      status: status,
      teamA: teamA,
      teamB: teamB,
      scores: scores,
      result: result.isEmpty ? null : result,
      toss: _stringOrNull(value['toss']),
      commentary: [
        if (_stringOrNull(value['need_run_ball']) != null)
          CommentaryEvent(
            id: 'need-${value['match_id'] ?? title.hashCode}',
            over: 0,
            ball: 0,
            text: '${value['need_run_ball']}',
            type: AlertEventType.normal,
            timestamp: DateTime.now(),
          ),
      ],
    );
  }

  CricketMatch _enrichMatch(
    CricketMatch match, {
    required dynamic scorecard,
    required dynamic commentary,
    required dynamic players,
    dynamic fallbackPlayers,
  }) {
    final parsedScorecard = _parseScorecard(scorecard);
    final parsedCommentary = _parseCommentary(commentary);
    final parsedPlayers = _parsePlayers(players, match.teamA, match.teamB);
    final parsedFallbackPlayers = parsedPlayers.isEmpty
        ? _parsePlayers(fallbackPlayers, match.teamA, match.teamB)
        : const <Player>[];
    return match.copyWith(
      scorecard: parsedScorecard ?? match.scorecard,
      commentary: parsedCommentary.isEmpty
          ? match.commentary
          : parsedCommentary.take(80).toList(),
      players: parsedPlayers.isEmpty
          ? parsedFallbackPlayers.isEmpty
                ? match.players
                : parsedFallbackPlayers
          : parsedPlayers,
    );
  }

  List<CricketMatch> _parseMatches(
    dynamic payload, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    final items = _extractItems(payload);
    if (items is! List || items.isEmpty) return const [];

    return items.take(20).map((item) {
      if (item is! Map) return _emptyMatch('${item.hashCode}');
      final name =
          '${item['name'] ?? item['title'] ?? item['match_title'] ?? 'Live cricket match'}';
      final teamNames = _teamNames(item, name);
      final teamA = Team(
        id: teamNames.first.toLowerCase().replaceAll(' ', '-'),
        name: teamNames.first,
        shortName: _shortName(item, 0, teamNames.first),
        country: teamNames.first,
      );
      final teamB = Team(
        id: teamNames.last.toLowerCase().replaceAll(' ', '-'),
        name: teamNames.last,
        shortName: _shortName(item, 1, teamNames.last),
        country: teamNames.last,
      );
      final statusText = '${item['status'] ?? item['matchStatus'] ?? ''}'
          .toLowerCase();
      final status =
          statusText.contains('won') || statusText.contains('complete')
          ? MatchStatus.completed
          : statusText.contains('not started') ||
                statusText.contains('upcoming')
          ? MatchStatus.upcoming
          : defaultStatus;
      return _emptyMatch(_matchId(item, name)).copyWith(
        id: _matchId(item, name),
        title: name,
        series:
            '${item['series'] ?? item['seriesName'] ?? item['competition']?['title'] ?? item['series_name'] ?? item['match_subtitle'] ?? 'Cricket'}',
        venue:
            '${item['venue'] ?? item['venue_name'] ?? item['ground'] ?? 'Venue updating'}',
        startTime: _parseDate(item['date']) ?? DateTime.now(),
        status: status,
        teamA: teamA,
        teamB: teamB,
        result: status == MatchStatus.completed
            ? '${item['result'] ?? item['status'] ?? 'Match completed'}'
            : null,
      );
    }).toList();
  }

  dynamic _extractItems(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return null;
    final data = payload['data'];
    if (data is List) return data;
    if (data is Map) {
      for (final key in const [
        'fixtures',
        'results',
        'matches',
        'matchList',
        'data',
      ]) {
        final value = data[key];
        if (value is List) return value;
      }
    }
    for (final key in const [
      'fixtures',
      'results',
      'series',
      'matches',
      'matchList',
      'response',
    ]) {
      final value = payload[key];
      if (value is List) return value;
    }
    return null;
  }

  dynamic _payloadData(dynamic payload) {
    if (payload is Map && payload['data'] != null) return payload['data'];
    return payload;
  }

  List<String> _teamNames(Map item, String name) {
    if (item['teams'] is List && (item['teams'] as List).length >= 2) {
      return List<String>.from(item['teams']).take(2).toList();
    }
    final home = item['home'] ?? item['home_team'] ?? item['localteam'];
    final away = item['away'] ?? item['away_team'] ?? item['visitorteam'];
    final homeName = _entityName(home);
    final awayName = _entityName(away);
    if (homeName != null && awayName != null) return [homeName, awayName];
    final teamA = _entityName(item['team_a'] ?? item['teamA']);
    final teamB = _entityName(item['team_b'] ?? item['teamB']);
    if (teamA != null && teamB != null) return [teamA, teamB];
    final split = name.split(RegExp(r'\s+v(?:s)?\.?\s+', caseSensitive: false));
    if (split.length >= 2) return [split.first, split[1]];
    final tour = name.split(RegExp(r'\s+in\s+', caseSensitive: false));
    if (tour.length >= 2) return [tour.first, tour[1]];
    return const ['Team A', 'Team B'];
  }

  String _shortName(Map item, int index, String fallback) {
    final home = index == 0 ? item['home'] : item['away'];
    final code = _entityCode(home);
    if (code != null) return code;
    final info = item['teamInfo'];
    if (info is List && info.length > index && info[index] is Map) {
      return '${info[index]['shortname'] ?? info[index]['name'] ?? fallback}';
    }
    return fallback.length <= 3
        ? fallback.toUpperCase()
        : fallback.substring(0, 3).toUpperCase();
  }

  String _matchId(Map item, String name) =>
      '${item['id'] ?? item['fixture_id'] ?? item['match_id'] ?? item['unique_id'] ?? item['series_id'] ?? name.hashCode}';

  String? _entityName(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is Map) {
      for (final key in const ['name', 'title', 'team_name', 'short_name']) {
        final item = value[key];
        if (item is String && item.trim().isNotEmpty) return item;
      }
    }
    return null;
  }

  String? _entityCode(dynamic value) {
    if (value is Map) {
      final code = value['code'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }

  DateTime _parseLineDate(dynamic dateWise, dynamic time) {
    final value = '${dateWise ?? ''} ${time ?? ''}'.trim();
    if (value.isEmpty) return DateTime.now();
    final formats = [
      RegExp(r'^(\d{2}) ([A-Za-z]{3}) (\d{4})'),
      RegExp(r'^(\d{2})-([A-Za-z]{3})'),
    ];
    for (final format in formats) {
      final match = format.firstMatch(value);
      if (match == null) continue;
      final day = int.tryParse(match.group(1) ?? '');
      final month = _monthNumber(match.group(2));
      final year = int.tryParse(match.group(3) ?? '') ?? DateTime.now().year;
      if (day != null && month != null) return DateTime(year, month, day);
    }
    return DateTime.now();
  }

  int? _monthNumber(String? month) {
    if (month == null) return null;
    return const {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    }[month.toLowerCase()];
  }

  MatchStatus _lineStatus(dynamic value, MatchStatus fallback) {
    final text = '$value'.toLowerCase();
    if (text.contains('finish') || text.contains('complete')) {
      return MatchStatus.completed;
    }
    if (text.contains('upcoming') || text.contains('not started')) {
      return MatchStatus.upcoming;
    }
    if (text.contains('live') || text == '2') return MatchStatus.live;
    return fallback;
  }

  InningsScore? _scoreFromLine(Map item, Team team, String prefix) {
    final scoreText = '${item['${prefix}_scores'] ?? ''}'.trim();
    final overText = '${item['${prefix}_over'] ?? ''}'.trim();
    if (scoreText.isEmpty && overText.isEmpty) return null;
    final parts = scoreText.split('-');
    final runs = int.tryParse(parts.first) ?? 0;
    final wickets = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return InningsScore(
      teamId: team.id,
      runs: runs,
      wickets: wickets,
      overs: double.tryParse(overText) ?? 0,
    );
  }

  Scorecard? _parseScorecard(dynamic payload) {
    final data = _payloadData(payload);
    if (data is! Map || data['scorecard'] is! Map) return null;
    final batting = <BattingLine>[];
    final bowling = <BowlingLine>[];
    for (final inning in (data['scorecard'] as Map).values) {
      if (inning is! Map) continue;
      final team = inning['team'];
      final battingTeamId = team is Map ? '${team['team_id'] ?? ''}' : null;
      final batsmen = inning['batsman'];
      if (batsmen is List) {
        for (final item in batsmen.whereType<Map>()) {
          batting.add(
            BattingLine(
              playerName: '${item['name'] ?? 'Batter'}',
              runs: _int(item['run']),
              balls: _int(item['ball']),
              fours: _int(item['fours']),
              sixes: _int(item['sixes']),
              outText: '${item['out_by'] ?? 'not out'}',
              teamId: battingTeamId,
            ),
          );
        }
      }
      final bowlers = inning['bolwer'] ?? inning['bowler'];
      if (bowlers is List) {
        for (final item in bowlers.whereType<Map>()) {
          bowling.add(
            BowlingLine(
              playerName: '${item['name'] ?? 'Bowler'}',
              overs: double.tryParse('${item['over'] ?? 0}') ?? 0,
              runs: _int(item['run']),
              wickets: _int(item['wicket']),
              maidens: _int(item['maiden']),
              teamId: null,
            ),
          );
        }
      }
    }
    if (batting.isEmpty && bowling.isEmpty) return null;
    return Scorecard(batting: batting, bowling: bowling);
  }

  List<CommentaryEvent> _parseCommentary(dynamic payload) {
    final data = _payloadData(payload);
    if (data is! Map) return const [];
    final events = <CommentaryEvent>[];
    void readNode(dynamic node) {
      if (node is Map && node['data'] is Map) {
        final item = node['data'] as Map;
        final overText = '${item['overs'] ?? item['over'] ?? '0.0'}';
        final split = overText.split('.');
        final title = '${item['title'] ?? ''}'.trim();
        final description = '${item['description'] ?? ''}'.trim();
        if (title.isEmpty && description.isEmpty) return;
        events.add(
          CommentaryEvent(
            id: '${node['commentary_id'] ?? title.hashCode}',
            over: int.tryParse(split.first) ?? 0,
            ball: split.length > 1 ? int.tryParse(split[1]) ?? 0 : 0,
            text: description.isEmpty ? title : '$title. $description',
            type: _eventType(item),
            timestamp: DateTime.now(),
          ),
        );
      } else if (node is Map) {
        for (final value in node.values) {
          readNode(value);
        }
      } else if (node is List) {
        for (final value in node) {
          readNode(value);
        }
      }
    }

    readNode(data);
    events.sort((a, b) {
      final over = b.over.compareTo(a.over);
      return over == 0 ? b.ball.compareTo(a.ball) : over;
    });
    return events;
  }

  List<Player> _parsePlayers(dynamic payload, Team teamA, Team teamB) {
    final data = _payloadData(payload);
    if (data is! Map) return const [];
    final players = <Player>[];
    void addTeam(String key, Team team) {
      final section = data[key];
      if (section is! Map || section['player'] is! List) return;
      for (final item in (section['player'] as List).whereType<Map>()) {
        players.add(
          Player(
            id: '${item['player_id'] ?? item['name'] ?? players.length}',
            name: '${item['name'] ?? 'Player'}',
            role: '${item['play_role'] ?? 'Player'}',
            teamId: team.id,
            battingStyle: _stringOrNull(
              item['batting_style'] ?? item['battingStyle'],
            ),
            bowlingStyle: _stringOrNull(
              item['bowling_style'] ?? item['bowlingStyle'],
            ),
          ),
        );
      }
    }

    addTeam('team_a', teamA);
    addTeam('team_b', teamB);
    return players;
  }

  AlertEventType _eventType(Map item) {
    final title = '${item['title'] ?? ''}'.toLowerCase();
    final description = '${item['description'] ?? ''}'.toLowerCase();
    final runs = '${item['runs'] ?? ''}';
    final wicket = '${item['wicket'] ?? ''}'.trim();
    if (wicket.isNotEmpty || title.contains('wicket')) {
      return AlertEventType.wicket;
    }
    if (runs == '6' || title.contains('six')) return AlertEventType.six;
    if (runs == '4' || title.contains('four')) return AlertEventType.four;
    if (title.contains('century') || description.contains('century')) {
      return AlertEventType.century;
    }
    if (title.contains('fifty') || description.contains('fift')) {
      return AlertEventType.fifty;
    }
    if (title.contains('end of over')) return AlertEventType.normal;
    return AlertEventType.normal;
  }

  int _int(dynamic value) => int.tryParse('$value') ?? 0;

  String? _stringOrNull(dynamic value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  List<CricketMatch> _dedupeMatches(List<CricketMatch> matches) {
    final seen = <String>{};
    final result = <CricketMatch>[];
    for (final match in matches) {
      if (seen.add(match.id)) result.add(match);
    }
    return result;
  }

  CricketMatch _emptyMatch(String id) {
    const teamA = Team(
      id: 'team-a',
      name: 'Team A',
      shortName: 'TMA',
      country: 'Unknown',
    );
    const teamB = Team(
      id: 'team-b',
      name: 'Team B',
      shortName: 'TMB',
      country: 'Unknown',
    );
    return CricketMatch(
      id: id,
      title: 'Live cricket match',
      series: 'Cricket',
      venue: 'Venue updating',
      startTime: DateTime.now(),
      status: MatchStatus.live,
      teamA: teamA,
      teamB: teamB,
      scores: const [],
      commentary: const [],
      scorecard: const Scorecard(batting: [], bowling: []),
      players: const [],
    );
  }
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.createdAt);

  final T value;
  final DateTime createdAt;
}
