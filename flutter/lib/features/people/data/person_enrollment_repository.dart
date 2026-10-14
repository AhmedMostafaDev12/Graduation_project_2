import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/people_data.dart';
import '../domain/person_enrollment.dart';

class PersonEnrollmentRepository {
  PersonEnrollmentRepository(this.client, this.db, this.scope);
  final ApiClient client;
  final RemoriDatabase db;
  final PeopleScope scope;
  final _cancel = CancelToken();
  void dispose() => _cancel.cancel();

  Future<CachedPeopleCompanion> create(PersonEnrollment draft) async {
    if (!draft.valid) {
      throw ApiFailure(ApiFailureKind.server, code: 'VALIDATION_ERROR');
    }
    final body = FormData();
    body.fields.addAll([
      MapEntry('name', draft.name.trim()),
      MapEntry('relationship', draft.relationship.trim()),
      const MapEntry('consent_given', 'true'),
    ]);
    for (var i = 0; i < draft.photos.length; i++) {
      final photo = draft.photos[i];
      body.files.add(
        MapEntry(
          'photos',
          MultipartFile.fromBytes(
            photo.bytes,
            filename: 'photo-${i + 1}.${photo.jpeg ? 'jpg' : 'png'}',
            contentType: DioMediaType('image', photo.jpeg ? 'jpeg' : 'png'),
          ),
        ),
      );
    }
    final response = await client.request<dynamic>(
      '/patients/${scope.patientId}/people',
      method: 'POST',
      credential: ApiCredential.caregiver,
      data: body,
      cancelToken: _cancel,
    );
    final value = response.data;
    if (response.statusCode != 201 ||
        value is! Map ||
        value['id'] is! String ||
        (value['id'] as String).isEmpty ||
        value['patient_id'] != scope.patientId ||
        value['status'] != 'active' ||
        value['name'] is! String ||
        (value['name'] as String).trim().isEmpty ||
        value['relationship'] is! String ||
        (value['relationship'] as String).trim().isEmpty ||
        value['embedding_count'] is! int ||
        (value['embedding_count'] as int) < 0) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    final updated = DateTime.tryParse(
      value['updated_at'] is String ? value['updated_at'] as String : '',
    );
    if (updated == null || !updated.isUtc) {
      throw ApiFailure(ApiFailureKind.invalidResponse);
    }
    return CachedPeopleCompanion.insert(
      caregiverId: scope.caregiverId,
      patientId: scope.patientId,
      id: value['id'] as String,
      name: value['name'] as String,
      relationship: value['relationship'] as String,
      status: 'active',
      embeddingCount: value['embedding_count'] as int,
      updatedAt: updated,
      // The enrollment response has no thumbnail. C3 refresh obtains it.
      position: -1,
    );
  }

  Future<void> cache(CachedPeopleCompanion person) => db.transaction(() async {
    await db
        .into(db.cachedPeople)
        .insert(person, mode: InsertMode.insertOrReplace);
  });
}
