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
    this.samples = const [],
  });
  final String id;
  final int sightingCount, distinctDays;
  final DateTime firstSeenAt, lastSeenAt;
  final String? sampleId, sampleUrl, thumbnailUrl;
  final List<UnknownFaceSample> samples;
  String? get previewUrl => thumbnailUrl ?? sampleUrl;
}

class UnknownFaceSample {
  const UnknownFaceSample(this.id, this.url, this.thumbnailUrl);
  final String id, url;
  final String? thumbnailUrl;
  UnknownFace preview(UnknownFace face) => UnknownFace(
    id: face.id,
    sightingCount: face.sightingCount,
    distinctDays: face.distinctDays,
    firstSeenAt: face.firstSeenAt,
    lastSeenAt: face.lastSeenAt,
    sampleId: id,
    sampleUrl: url,
    thumbnailUrl: thumbnailUrl,
  );
}

class UnknownFacesData {
  const UnknownFacesData({this.faces = const [], this.refreshedAt});
  final List<UnknownFace> faces;
  final DateTime? refreshedAt;
}
