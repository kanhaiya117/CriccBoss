import 'dart:async';

import 'package:cricboss/src/config/app_config.dart';
import 'package:cricboss/src/data/datasources/cricket_remote_datasource.dart';
import 'package:cricboss/src/domain/models/cricket_models.dart';
import 'package:cricboss/src/domain/repositories/cricket_repository.dart';

class CricketRepositoryImpl implements CricketRepository {
  CricketRepositoryImpl(this._dataSource);

  final CricketDataSource _dataSource;

  @override
  Future<List<CricketMatch>> getMatches() => _dataSource.getMatches();

  @override
  Future<CricketMatch> getMatch(String id) => _dataSource.getMatch(id);

  @override
  Stream<List<CricketMatch>> watchMatches() async* {
    yield await getMatches();
    yield* Stream.periodic(AppConfig.liveRefresh).asyncMap((_) => getMatches());
  }
}
