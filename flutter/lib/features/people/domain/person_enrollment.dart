import 'dart:typed_data';

class EnrollmentPhoto {
  EnrollmentPhoto(this.bytes);
  final Uint8List bytes;
  bool get jpeg =>
      bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255;
  bool get png =>
      bytes.length >= 8 &&
      bytes[0] == 137 &&
      bytes[1] == 80 &&
      bytes[2] == 78 &&
      bytes[3] == 71 &&
      bytes[4] == 13 &&
      bytes[5] == 10 &&
      bytes[6] == 26 &&
      bytes[7] == 10;
  String? get problem => bytes.length > 4 * 1024 * 1024
      ? 'PHOTO_TOO_LARGE'
      : !jpeg && !png
      ? 'UNSUPPORTED_PHOTO'
      : null;
}

class PersonEnrollment {
  PersonEnrollment({
    required this.name,
    required this.relationship,
    required this.consent,
    required List<EnrollmentPhoto> photos,
  }) : photos = List.unmodifiable(photos);
  final String name, relationship;
  final bool consent;
  final List<EnrollmentPhoto> photos;
  bool get valid =>
      name.trim().isNotEmpty &&
      name.trim().runes.length <= 80 &&
      relationship.trim().isNotEmpty &&
      relationship.trim().runes.length <= 40 &&
      consent &&
      photos.isNotEmpty &&
      photos.length <= 5 &&
      photos.every((p) => p.problem == null);
}
