import 'package:cricboss/src/data/mock/mock_cricket_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock mode provides non-empty cricket data', () {
    final matches = MockCricketFactory().matches();
    expect(matches, isNotEmpty);
    expect(matches.first.commentary, isNotEmpty);
    expect(matches.first.players, isNotEmpty);
    expect(matches.first.scoreSummary, isNotEmpty);
  });
}
