import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../domain/person_enrollment.dart';

abstract interface class EnrollmentPhotoPicker {
  Future<EnrollmentPhoto?> pick({required bool camera});
  Future<List<EnrollmentPhoto>> recover();
}

class NativeEnrollmentPhotoPicker implements EnrollmentPhotoPicker {
  final _picker = ImagePicker();
  Future<EnrollmentPhoto> _read(XFile file) async {
    // Do not read an unbounded private image into memory.
    if (await file.length() > 4 * 1024 * 1024) {
      throw const PhotoSelectionFailure('PHOTO_TOO_LARGE');
    }
    final photo = EnrollmentPhoto(await file.readAsBytes());
    if (photo.problem case final String problem) {
      throw PhotoSelectionFailure(problem);
    }
    return photo;
  }

  @override
  Future<EnrollmentPhoto?> pick({required bool camera}) async {
    final file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<List<EnrollmentPhoto>> recover() async {
    if (!Platform.isAndroid) return [];
    final data = await _picker.retrieveLostData();
    if (data.exception != null) {
      throw const PhotoSelectionFailure('PICK_FAILED');
    }
    return [for (final file in data.files ?? <XFile>[]) await _read(file)];
  }
}

class PhotoSelectionFailure implements Exception {
  const PhotoSelectionFailure(this.code);
  final String code;
  @override
  String toString() => 'PhotoSelectionFailure($code)';
}
