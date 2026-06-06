import 'dart:async';

import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/data/datasources/cricket_remote_datasource.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/domain/repositories/cricket_repository.dart';
import 'package:cricboss/src/services/local_storage_service.dart';

class CricketRepositoryImpl implements CricketRepository {
  CricketRepositoryImpl(this._dataSource, this._storage);

  final CricketDataSource _dataSource;
  final LocalStorageService _storage;

  @override
  Future<List<CricketMatch>> getMatches() async {
    try {
      final matches = await _dataSource.getMatches();
      if (matches.isNotEmpty) {
        final cached = _dataSource.usedStaleCache;
        final updatedAt = _dataSource.lastSuccessfulUpdate ?? DateTime.now();
        final fresh = matches
            .map(
              (match) =>
                  match.copyWith(lastUpdated: updatedAt, isCached: cached),
            )
            .toList();
        if (!cached) await _storage.cacheMatches(fresh);
        return fresh;
      }
    } catch (_) {}
    return _storage.cachedMatches;
  }

  @override
  Future<CricketMatch> getMatch(String id) async {
    try {
      final value = await _dataSource.getMatch(id);
      final cached = _dataSource.usedStaleCache;
      final match = value.copyWith(
        lastUpdated: _dataSource.lastSuccessfulUpdate ?? DateTime.now(),
        isCached: cached,
      );
      if (!cached) await _storage.cacheMatch(match);
      return match;
    } catch (_) {
      final cached = _storage.cachedMatch(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Stream<List<CricketMatch>> watchMatches() async* {
    yield await getMatches();
    yield* Stream.periodic(AppConfig.liveRefresh).asyncMap((_) => getMatches());
  }
}
