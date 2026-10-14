import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/db/remori_database.dart';
import '../domain/people_data.dart';
import '../domain/person_detail.dart';
import '../domain/person_enrollment.dart';
import 'people_photo_cache.dart';
import 'person_detail_photo_cache.dart';

class PersonDetailRepository {
  PersonDetailRepository(
    this.client,
    this.db,
    this.scope,
    this.photos,
    this.peoplePhotos,
  );
  final ApiClient client;
  final RemoriDatabase db;
  final PersonDetailScope scope;
  final PersonDetailPhotoCache photos;
  final PeoplePhotoCache peoplePhotos;
  final _cancel = CancelToken();
  bool _disposed = false;
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  String get _path => '/people/${scope.personId}';
  Expression<bool> _person(CachedPeople p) =>
      p.caregiverId.equals(scope.owner.caregiverId) &
      p.patientId.equals(scope.owner.patientId) &
      p.id.equals(scope.personId);
  Expression<bool> _photos(CachedPersonPhotos p) =>
      p.caregiverId.equals(scope.owner.caregiverId) &
      p.patientId.equals(scope.owner.patientId) &
      p.personId.equals(scope.personId);
  Expression<bool> _metadata(PersonDetailStates p) =>
      p.caregiverId.equals(scope.owner.caregiverId) &
      p.patientId.equals(scope.owner.patientId) &
      p.personId.equals(scope.personId);
  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _string(Map data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) throw _invalid;
    return value;
  }

  String _url(Object? value) {
    if (value is! String) throw _invalid;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw _invalid;
    }
    return value;
  }

  void _validate(Map data) {
    if (data['id'] != scope.personId ||
        data['patient_id'] != scope.owner.patientId ||
        !['active', 'archived'].contains(data['status']) ||
        data['embedding_count'] is! int ||
        (data['embedding_count'] as int) < 0) {
      throw _invalid;
    }
    _string(data, 'name');
    _string(data, 'relationship');
    final updated = DateTime.tryParse(_string(data, 'updated_at'));
    if (updated == null || !updated.isUtc) throw _invalid;
  }

  Future<Response<dynamic>> _request({
    String method = 'GET',
    String? suffix,
    Object? data,
  }) => client.request<dynamic>(
    '$_path${suffix ?? ''}',
    credential: ApiCredential.caregiver,
    method: method,
    data: data,
    cancelToken: _cancel,
  );
  Future<void> refresh() async {
    try {
      final response = await _request();
      final data = response.data;
      if (response.statusCode != 200 || data is! Map) throw _invalid;
      _validate(data);
      if (data['photos'] is! List ||
          (data['photos'] as List).length > 20 ||
          (data['enrolled_by_name'] != null &&
              data['enrolled_by_name'] is! String)) {
        throw _invalid;
      }
      final received = <EnrolledPhoto>[];
      final ids = <String>{};
      if (data['status'] == 'active') {
        for (final raw in data['photos'] as List) {
          if (raw is! Map) throw _invalid;
          final id = _string(raw, 'id');
          if (!ids.add(id)) throw _invalid;
          received.add(
            EnrolledPhoto(
              id: id,
              url: _url(raw['url']),
              thumbnailUrl: raw['thumbnail_url'] == null
                  ? null
                  : _url(raw['thumbnail_url']),
            ),
          );
        }
      }
      if (_disposed) return;
      final old = await read();
      final oldRow = await (db.select(
        db.cachedPeople,
      )..where(_person)).getSingleOrNull();
      await db.transaction(() async {
        await db
            .into(db.cachedPeople)
            .insert(
              CachedPeopleCompanion.insert(
                caregiverId: scope.owner.caregiverId,
                patientId: scope.owner.patientId,
                id: scope.personId,
                name: data['name'],
                relationship: data['relationship'],
                status: data['status'],
                embeddingCount: data['embedding_count'],
                updatedAt: DateTime.parse(data['updated_at']),
                position: oldRow?.position ?? -1,
                photoUrl: Value(
                  received.isEmpty
                      ? null
                      : received.first.thumbnailUrl ?? received.first.url,
                ),
              ),
              mode: InsertMode.insertOrReplace,
            );
        await (db.delete(db.cachedPersonPhotos)..where(_photos)).go();
        for (var i = 0; i < received.length; i++) {
          final photo = received[i];
          await db
              .into(db.cachedPersonPhotos)
              .insert(
                CachedPersonPhotosCompanion.insert(
                  caregiverId: scope.owner.caregiverId,
                  patientId: scope.owner.patientId,
                  personId: scope.personId,
                  id: photo.id,
                  url: photo.url,
                  thumbnailUrl: Value(photo.thumbnailUrl),
                  position: i,
                ),
              );
        }
        await db
            .into(db.personDetailStates)
            .insert(
              PersonDetailStatesCompanion.insert(
                caregiverId: scope.owner.caregiverId,
                patientId: scope.owner.patientId,
                personId: scope.personId,
                enrolledByName: Value(data['enrolled_by_name'] as String?),
                refreshedAt: DateTime.now().toUtc(),
              ),
              mode: InsertMode.insertOrReplace,
            );
      });
      for (final photo in old?.photos ?? <EnrolledPhoto>[]) {
        if (!ids.contains(photo.id)) await photos.evict(scope, photo);
      }
      if (old != null &&
          (data['status'] == 'archived' ||
              old.person.updatedAt != DateTime.parse(data['updated_at']))) {
        await peoplePhotos.evict(scope.owner, old.person);
      }
    } on ApiFailure catch (error) {
      if (error.statusCode == 404 && error.code == 'PERSON_NOT_FOUND') {
        await purge();
      }
      rethrow;
    }
  }

  Future<void> edit(String name, String relationship) async {
    if (name.trim().isEmpty ||
        name.trim().runes.length > 80 ||
        relationship.trim().isEmpty ||
        relationship.trim().runes.length > 40) {
      throw ApiFailure(ApiFailureKind.server, code: 'VALIDATION_ERROR');
    }
    await _write(
      'PATCH',
      data: {'name': name.trim(), 'relationship': relationship.trim()},
    );
  }

  Future<void> addPhotos(List<EnrollmentPhoto> selected) async {
    if (selected.isEmpty ||
        selected.length > 5 ||
        selected.any((p) => p.problem != null)) {
      throw ApiFailure(ApiFailureKind.server, code: 'PHOTO_COUNT');
    }
    final form = FormData();
    for (var i = 0; i < selected.length; i++) {
      final photo = selected[i];
      form.files.add(
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
    await _write('POST', suffix: '/photos', data: form);
  }

  Future<void> removePhoto(String id) async {
    final current = await read();
    if (current == null || !current.photos.any((p) => p.id == id)) {
      throw _invalid;
    }
    if (current.photos.length <= 1) {
      throw ApiFailure(ApiFailureKind.server, code: 'LAST_PHOTO');
    }
    await _write('DELETE', suffix: '/photos/$id');
  }

  Future<void> _write(String method, {String? suffix, Object? data}) async {
    final response = await _request(method: method, suffix: suffix, data: data);
    if (response.statusCode != 200 || response.data is! Map) throw _invalid;
    _validate(response.data as Map);
  }

  Future<void> archive() async {
    final response = await _request(method: 'DELETE');
    if (response.statusCode != 204) throw _invalid;
  }

  Future<void> cacheArchive() async {
    final old = await read();
    await db.transaction(() async {
      await (db.update(db.cachedPeople)..where(_person)).write(
        CachedPeopleCompanion(
          status: const Value('archived'),
          photoUrl: const Value(null),
          embeddingCount: const Value(0),
        ),
      );
      await (db.delete(db.cachedPersonPhotos)..where(_photos)).go();
      await (db.delete(db.personDetailStates)..where(_metadata)).go();
    });
    for (final photo in old?.photos ?? <EnrolledPhoto>[]) {
      await photos.evict(scope, photo);
    }
    if (old != null) await peoplePhotos.evict(scope.owner, old.person);
  }

  Future<void> purge() async {
    await cacheArchive();
    await (db.delete(db.cachedPeople)..where(_person)).go();
  }

  Stream<PersonDetailData?> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedPeople,
          db.cachedPersonPhotos,
          db.personDetailStates,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<PersonDetailData?> read() => db.transaction(() async {
    final person = await (db.select(
      db.cachedPeople,
    )..where(_person)).getSingleOrNull();
    if (person == null) return null;
    final metadata = await (db.select(
      db.personDetailStates,
    )..where(_metadata)).getSingleOrNull();
    final images =
        await (db.select(db.cachedPersonPhotos)
              ..where(_photos)
              ..orderBy([(p) => OrderingTerm.asc(p.position)]))
            .get();
    return PersonDetailData(
      person: KnownPerson(
        id: person.id,
        name: person.name,
        relationship: person.relationship,
        status: PeopleFilter.values.byName(person.status),
        updatedAt: person.updatedAt,
        photoUrl: person.photoUrl,
      ),
      enrolledByName: metadata?.enrolledByName,
      refreshedAt: metadata?.refreshedAt,
      photos: person.status == 'active'
          ? images.map(cachedEnrolledPhoto).toList()
          : [],
    );
  });
}
