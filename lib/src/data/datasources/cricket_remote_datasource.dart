import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/data/mock/mock_cricket_factory.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:dio/dio.dart';

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

  List<CricketMatch> _parseMatches(dynamic payload) {
    final items = payload is Map
        ? payload['data'] ?? payload['matches']
        : payload;
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
          : MatchStatus.live;
      return fallback.first.copyWith(
        id: '${item['id'] ?? item['unique_id'] ?? name.hashCode}',
        title: name,
        series: '${item['series'] ?? item['seriesName'] ?? 'Cricket'}',
        venue: '${item['venue'] ?? 'Venue updating'}',
        status: status,
        teamA: teamA,
        teamB: teamB,
        result: status == MatchStatus.completed
            ? '${item['status'] ?? 'Match completed'}'
            : null,
      );
    }).toList();
  }

  List<String> _teamNames(Map item, String name) {
    if (item['teams'] is List && (item['teams'] as List).length >= 2) {
      return List<String>.from(item['teams']).take(2).toList();
    }
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
}
