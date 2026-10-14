enum PeopleFilter { active, archived }

class PeopleScope {
  const PeopleScope(this.caregiverId, this.patientId);
  final String caregiverId, patientId;
  @override
  bool operator ==(Object other) =>
      other is PeopleScope &&
      other.caregiverId == caregiverId &&
      other.patientId == patientId;
  @override
  int get hashCode => Object.hash(caregiverId, patientId);
}

class KnownPerson {
  const KnownPerson({
    required this.id,
    required this.name,
    required this.relationship,
    required this.status,
    required this.updatedAt,
    this.photoUrl,
  });
  final String id, name, relationship;
  final PeopleFilter status;
  final DateTime updatedAt;
  final String? photoUrl;
  String imageKey(PeopleScope scope) =>
      'remori:${scope.caregiverId}:${scope.patientId}:$id:${updatedAt.microsecondsSinceEpoch}';
}

class PeopleData {
  const PeopleData({
    this.people = const [],
    this.unknownCount = 0,
    this.refreshedAt,
  });
  final List<KnownPerson> people;
  final int unknownCount;
  final DateTime? refreshedAt;
  bool get loaded => refreshedAt != null;
}
