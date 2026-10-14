class UnknownFace {
  const UnknownFace({
    required this.id,
    required this.sightingCount,
    required this.distinctDays,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.sampleId,
    this.sampleUrl,
    this.thumbnailUrl,
  });
  final String id;
  final int sightingCount, distinctDays;
  final DateTime firstSeenAt, lastSeenAt;
  final String? sampleId, sampleUrl, thumbnailUrl;
  String? get previewUrl => thumbnailUrl ?? sampleUrl;
}

class UnknownFacesData {
  const UnknownFacesData({this.faces = const [], this.refreshedAt});
  final List<UnknownFace> faces;
  final DateTime? refreshedAt;
}
