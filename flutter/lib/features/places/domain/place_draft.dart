class PlacePoint {
  const PlacePoint(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;
}

class PlaceDraft {
  const PlaceDraft({this.name = '', this.point, this.radiusM = 100});
  final String name;
  final PlacePoint? point;
  final int radiusM;
  bool get valid =>
      name.trim().isNotEmpty &&
      name.trim().runes.length <= 80 &&
      point?.valid == true &&
      radiusM >= 20 &&
      radiusM <= 2000;
  bool get sliderCompatible =>
      radiusM >= 50 && radiusM <= 500 && radiusM % 10 == 0;
  PlaceDraft copyWith({String? name, PlacePoint? point, int? radiusM}) =>
      PlaceDraft(
        name: name ?? this.name,
        point: point ?? this.point,
        radiusM: radiusM ?? this.radiusM,
      );
}
