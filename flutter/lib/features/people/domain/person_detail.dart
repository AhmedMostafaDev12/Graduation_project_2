import 'people_data.dart';

class PersonDetailScope {
  const PersonDetailScope(this.owner, this.personId);
  final PeopleScope owner;
  final String personId;
  @override
  bool operator ==(Object other) =>
      other is PersonDetailScope &&
      other.owner == owner &&
      other.personId == personId;
  @override
  int get hashCode => Object.hash(owner, personId);
}

class EnrolledPhoto {
  const EnrolledPhoto({required this.id, required this.url, this.thumbnailUrl});
  final String id, url;
  final String? thumbnailUrl;
  String key(PersonDetailScope scope, {required bool full}) =>
      'remori:${scope.owner.caregiverId}:${scope.owner.patientId}:${scope.personId}:$id:${full ? 'full' : 'thumb'}';
}

class PersonDetailData {
  const PersonDetailData({
    required this.person,
    this.enrolledByName,
    this.photos = const [],
    this.refreshedAt,
  });
  final KnownPerson person;
  final String? enrolledByName;
  final List<EnrolledPhoto> photos;
  final DateTime? refreshedAt;
}
