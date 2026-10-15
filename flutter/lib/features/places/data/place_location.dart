import 'package:geolocator/geolocator.dart';

import '../domain/place_draft.dart';

abstract interface class PlaceLocation {
  Future<PlacePoint?> current();
}

/// Only called for a new place on the caregiver phone; no tracking stream.
class NativePlaceLocation implements PlaceLocation {
  @override
  Future<PlacePoint?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = PlacePoint(p.latitude, p.longitude);
      return point.valid ? point : null;
    } catch (_) {
      // Neither coordinates nor platform exceptions enter diagnostic output.
      return null;
    }
  }
}
