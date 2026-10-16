import '../../patient_today/domain/patient_today_data.dart';

typedef GameResultTarget = ({PatientTodayKey scope, String id});
typedef GameUiTarget = ({PatientTodayKey? scope, String type});

class GamePerson {
  const GamePerson(this.id, this.name, this.url, this.validUntil);
  final String id, name, url;
  final DateTime validUntil;
}

class GameSession {
  const GameSession(this.id, this.score, this.seconds, this.completedAt);
  final String id;
  final int score, seconds;
  final DateTime completedAt;
  Map<String, Object?> payload() => {
    'id': id,
    'game_type': 'face_match',
    'score': score,
    'duration_seconds': seconds,
    'completed_at': completedAt.toUtc().toIso8601String(),
  };
}

/// Four cards; matches never cost points and a wrong pair waits before hiding.
class CardRound {
  CardRound(
    List<int> cards, {
    Set<int> matched = const {},
    this.first,
    this.second,
  }) : cards = List.unmodifiable(cards),
       matched = Set.unmodifiable(matched);
  final List<int> cards;
  final Set<int> matched;
  final int? first, second;
  int get score => matched.length ~/ 2;
  bool get waiting => second != null;
  bool up(int index) =>
      matched.contains(index) || first == index || second == index;
  CardRound pick(int index) {
    if (index < 0 || index >= 4 || waiting || up(index)) return this;
    if (first == null) return CardRound(cards, matched: matched, first: index);
    if (cards[first!] == cards[index]) {
      return CardRound(cards, matched: {...matched, first!, index});
    }
    return CardRound(cards, matched: matched, first: first, second: index);
  }

  CardRound hideMismatch() => CardRound(cards, matched: matched);
}
