import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/data/mock/mock_cricket_factory.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class CricketDataSource {
  Future<List<CricketMatch>> getMatches();
  Future<CricketMatch> getMatch(String id);
}

class FailoverCricketDataSource implements CricketDataSource {
  FailoverCricketDataSource(this._dio, this._mock);

  final Dio _dio;
  final MockCricketFactory _mock;

  @override
  Future<List<CricketMatch>> getMatches() async {
    if (kMockMode) return _mock.matches();
    final cricketData = await _tryCricketData();
    if (cricketData.isNotEmpty) return cricketData;
    final cricApi = await _tryCricApi();
    if (cricApi.isNotEmpty) return cricApi;
    final rapidApi = await _tryRapidApiCricket();
    if (rapidApi.isNotEmpty) return rapidApi;
    return _mock.matches();
  }

  @override
  Future<CricketMatch> getMatch(String id) async {
    final matches = await getMatches();
    return matches.firstWhere(
      (match) => match.id == id,
      orElse: () => _mock.matches().first,
    );
  }

  Future<List<CricketMatch>> _tryCricketData() async {
    if (AppConfig.cricketDataApiKey.isEmpty) return const [];
    try {
      final response = await _dio.get(
        '${AppConfig.cricketDataBaseUrl}/matches',
        queryParameters: {'apikey': AppConfig.cricketDataApiKey},
      );
      return _parseMatches(response.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CricketMatch>> _tryCricApi() async {
    if (AppConfig.cricApiKey.isEmpty) return const [];
    try {
      final response = await _dio.get(
        '${AppConfig.cricApiBaseUrl}/currentMatches',
        queryParameters: {'apikey': AppConfig.cricApiKey},
      );
      return _parseMatches(response.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<CricketMatch>> _tryRapidApiCricket() async {
    if (AppConfig.rapidApiCricketKey.isEmpty) return const [];
    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-rapidapi-host': AppConfig.rapidApiCricketHost,
        'x-rapidapi-key': AppConfig.rapidApiCricketKey,
      };
      final fixtures = await _dio.get(
        '${AppConfig.rapidApiCricketBaseUrl}/fixtures',
        options: Options(headers: headers),
      );
      final results = await _dio.get(
        '${AppConfig.rapidApiCricketBaseUrl}/results',
        options: Options(headers: headers),
      );

      final parsed = [
        ..._parseMatches(fixtures.data, defaultStatus: MatchStatus.upcoming),
        ..._parseMatches(results.data, defaultStatus: MatchStatus.completed),
      ];
      return _dedupeMatches(parsed);
    } catch (_) {
      return const [];
    }
  }

  @visibleForTesting
  List<CricketMatch> parseProviderMatchesForTest(
    dynamic payload, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    return _parseMatches(payload, defaultStatus: defaultStatus);
  }

  List<CricketMatch> _parseMatches(
    dynamic payload, {
    MatchStatus defaultStatus = MatchStatus.live,
  }) {
    final items = _extractItems(payload);
    if (items is! List || items.isEmpty) return const [];

    final fallback = _mock.matches();
    return items.take(20).map((item) {
      if (item is! Map) return fallback.first;
      final name = '${item['name'] ?? item['title'] ?? 'Live cricket match'}';
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
      return fallback.first.copyWith(
        id: _matchId(item, name),
        title: name,
        series:
            '${item['series'] ?? item['seriesName'] ?? item['competition']?['title'] ?? item['series_name'] ?? 'Cricket'}',
        venue:
            '${item['venue'] ?? item['venue_name'] ?? item['ground'] ?? 'Venue updating'}',
        status: status,
        teamA: teamA,
        teamB: teamB,
        result: status == MatchStatus.completed
            ? '${item['status'] ?? 'Match completed'}'
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
      'matches',
      'matchList',
      'response',
    ]) {
      final value = payload[key];
      if (value is List) return value;
    }
    return null;
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
    return const ['Team A', 'Team B'];
  }

  String _shortName(Map item, int index, String fallback) {
    final info = item['teamInfo'];
    if (info is List && info.length > index && info[index] is Map) {
      return '${info[index]['shortname'] ?? info[index]['name'] ?? fallback}';
    }
    return fallback.length <= 3
        ? fallback.toUpperCase()
        : fallback.substring(0, 3).toUpperCase();
  }

  String _matchId(Map item, String name) =>
      '${item['id'] ?? item['fixture_id'] ?? item['match_id'] ?? item['unique_id'] ?? name.hashCode}';

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

  List<CricketMatch> _dedupeMatches(List<CricketMatch> matches) {
    final seen = <String>{};
    final result = <CricketMatch>[];
    for (final match in matches) {
      if (seen.add(match.id)) result.add(match);
    }
    return result;
  }
}
