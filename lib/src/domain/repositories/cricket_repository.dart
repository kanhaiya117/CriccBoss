import 'package:cricboss/src/domain/models/cricket_models.dart';

abstract class CricketRepository {
  Future<List<CricketMatch>> getMatches();
  Future<CricketMatch> getMatch(String id);
  Stream<List<CricketMatch>> watchMatches();
}
