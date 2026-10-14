class PlacesScope {
  const PlacesScope(this.caregiverId, this.patientId);
  final String caregiverId, patientId;
  @override
  bool operator ==(Object other) =>
      other is PlacesScope &&
      other.caregiverId == caregiverId &&
      other.patientId == patientId;
  @override
  int get hashCode => Object.hash(caregiverId, patientId);
}

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
    required this.createdBy,
    required this.updatedAt,
  });
  final String id, name, createdBy;
  final double latitude, longitude;
  final int radiusM;
  final DateTime updatedAt;
}

class PlacesData {
  const PlacesData({this.places = const [], this.refreshedAt});
  final List<SavedPlace> places;
  final DateTime? refreshedAt;
}
