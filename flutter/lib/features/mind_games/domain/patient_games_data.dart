const patientGameTypes = ['face_match', 'picture_naming', 'word_recall'];

class PatientGameScore {
  const PatientGameScore(
    this.id,
    this.type,
    this.score,
    this.durationSeconds,
    this.completedAt,
  );
  final String id, type;
  final int score, durationSeconds;
  final DateTime completedAt;
}

class PatientGamesData {
  const PatientGamesData({this.scores = const {}, this.refreshed = const {}});
  final Map<String, PatientGameScore> scores;
  final Set<String> refreshed;
}
