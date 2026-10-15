import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_failure.dart';
import '../../../core/api/credential_store.dart';
import '../../../core/db/remori_database.dart';
import '../../people/data/people_photo_cache.dart';
import '../../people/data/person_detail_photo_cache.dart';
import '../../people/domain/people_data.dart';
import '../../people/domain/person_detail.dart';
import '../domain/home_data.dart';
import '../domain/more_data.dart';
import 'home_repository.dart';

class MoreRepository {
  MoreRepository(
    this.client,
    this.db,
    this.home,
    this.credentials,
    this.scope,
    this.peoplePhotos,
    this.personPhotos,
    this.clock,
  );
  final ApiClient client;
  final RemoriDatabase db;
  final HomeRepository home;
  final CredentialStore credentials;
  final MoreScope scope;
  final PeoplePhotoCache peoplePhotos;
  final PersonDetailPhotoCache personPhotos;
  final DateTime Function() clock;
  final _cancel = CancelToken();
  int _generation = 0;
  bool _disposed = false, _logoutAcknowledged = false;
  void Function(String)? invalidatePerson;
  bool get logoutAcknowledged => _logoutAcknowledged;
  void dispose() {
    _disposed = true;
    ++_generation;
    _cancel.cancel();
  }

  ApiFailure get _invalid => ApiFailure(ApiFailureKind.invalidResponse);
  String _text(Map p, String key) {
    final v = p[key];
    if (v is! String || v.trim().isEmpty) throw _invalid;
    return v;
  }

  String? _optional(Map p, String key) {
    final v = p[key];
    if (v != null && v is! String) throw _invalid;
    return v as String?;
  }

  DateTime _time(Map p, String key) {
    final v = DateTime.tryParse(_text(p, key));
    if (v == null || !v.isUtc) throw _invalid;
    return v;
  }

  ConsentRecord _consent(Map p) {
    final type = _text(p, 'consent_type'),
        subject = _optional(p, 'subject_person_id');
    if (!{
          'ambient_audio_household',
          'cloud_processing',
          'face_enrollment',
        }.contains(type) ||
        (type == 'face_enrollment' && (subject == null || subject.isEmpty)) ||
        (p.containsKey('patient_id') && p['patient_id'] != scope.$2)) {
      throw _invalid;
    }
    return ConsentRecord(
      id: _text(p, 'id'),
      type: type,
      givenBy: _text(p, 'given_by'),
      givenAt: _time(p, 'given_at'),
      revokedAt: p['revoked_at'] == null ? null : _time(p, 'revoked_at'),
      subjectId: subject,
      subjectName: _optional(p, 'subject_name'),
    );
  }

  Map<String, Object?> _payload(ConsentRecord c) => {
    'id': c.id,
    'consent_type': c.type,
    'subject_person_id': c.subjectId,
    'subject_name': c.subjectName,
    'given_by': c.givenBy,
    'given_at': c.givenAt.toIso8601String(),
    'revoked_at': c.revokedAt?.toIso8601String(),
  };
  Expression<bool> _consents(CachedConsents c) =>
      c.caregiverId.equals(scope.$1) & c.patientId.equals(scope.$2 ?? '');
  Future<DashboardPatient?> _patient() =>
      (db.select(db.dashboardPatients)..where(
            (p) => p.caregiverId.equals(scope.$1) & p.id.equals(scope.$2 ?? ''),
          ))
          .getSingleOrNull();
  Future<void> _manager() async {
    if ((await _patient())?.permission != 'manager') throw _invalid;
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final response = await client.request<dynamic>(
      '/auth/me',
      credential: ApiCredential.caregiver,
      cancelToken: _cancel,
    );
    final p = response.data;
    if (response.statusCode != 200 ||
        p is! Map ||
        p['id'] != scope.$1 ||
        p['role'] != 'caregiver') {
      throw _invalid;
    }
    final name = _text(p, 'full_name'), email = _text(p, 'email');
    final consents = <ConsentRecord>[];
    if (scope.$2 != null && await _patient() != null) {
      final raw = await home.getConsents(scope.$2!);
      if (raw is! List) throw _invalid;
      final ids = <String>{};
      for (final value in raw) {
        if (value is! Map) throw _invalid;
        final c = _consent(value);
        if (!ids.add(c.id)) throw _invalid;
        consents.add(c);
      }
    }
    if (_disposed || generation != _generation) return;
    await db.transaction(() async {
      if (_disposed || generation != _generation) return;
      await db
          .into(db.cachedCaregiverAccounts)
          .insert(
            CachedCaregiverAccountsCompanion.insert(
              id: scope.$1,
              fullName: name,
              email: email,
              refreshedAt: clock(),
            ),
            mode: InsertMode.insertOrReplace,
          );
      await (db.delete(db.cachedConsents)..where(_consents)).go();
      if (await _patient() == null) return;
      for (final c in consents) {
        await _cache(c);
      }
    });
    for (final c in consents.where(
      (c) => c.revokedAt != null && c.type == 'face_enrollment',
    )) {
      if (_disposed) return;
      await cacheRevocation(c);
    }
  }

  Future<void> _cache(ConsentRecord c) => db
      .into(db.cachedConsents)
      .insert(
        CachedConsentsCompanion.insert(
          caregiverId: scope.$1,
          patientId: scope.$2!,
          id: c.id,
          payload: jsonEncode(_payload(c)),
          refreshedAt: clock(),
        ),
        mode: InsertMode.insertOrReplace,
      );

  Future<ConsentRecord> revoke(String id) async {
    await _manager();
    final old = (await read()).consents
        .where((c) => c.id == id && c.revokedAt == null)
        .firstOrNull;
    if (old == null) throw _invalid;
    try {
      final response = await client.request<dynamic>(
        '/consents/$id/revoke',
        method: 'POST',
        credential: ApiCredential.caregiver,
        cancelToken: _cancel,
      );
      if (response.statusCode != 200 || response.data is! Map) throw _invalid;
      final c = _consent(response.data as Map);
      if (c.id != id ||
          c.type != old.type ||
          c.subjectId != old.subjectId ||
          c.givenBy != old.givenBy ||
          c.givenAt != old.givenAt ||
          c.revokedAt == null) {
        throw _invalid;
      }
      ++_generation;
      return c;
    } on ApiFailure catch (e) {
      if (e.statusCode == 409 && e.code == 'ALREADY_REVOKED') {
        await refresh();
        final c = (await read()).consents
            .where(
              (c) =>
                  c.id == id &&
                  c.type == old.type &&
                  c.subjectId == old.subjectId &&
                  c.revokedAt != null,
            )
            .firstOrNull;
        if (c != null) return c;
      }
      rethrow;
    }
  }

  Future<void> cacheRevocation(ConsentRecord c) async {
    ++_generation;
    if (_disposed || await _patient() == null) return;
    if (c.revokedAt == null) throw _invalid;
    if (c.type == 'face_enrollment' && c.subjectId != null) {
      invalidatePerson?.call(c.subjectId!);
      final owner = PeopleScope(scope.$1, scope.$2!),
          detailScope = PersonDetailScope(
            PeopleScope(scope.$1, scope.$2!),
            c.subjectId!,
          );
      final person =
          await (db.select(db.cachedPeople)..where(
                (p) =>
                    p.caregiverId.equals(scope.$1) &
                    p.patientId.equals(scope.$2!) &
                    p.id.equals(c.subjectId!),
              ))
              .getSingleOrNull();
      final photos =
          await (db.select(db.cachedPersonPhotos)..where(
                (p) =>
                    p.caregiverId.equals(scope.$1) &
                    p.patientId.equals(scope.$2!) &
                    p.personId.equals(c.subjectId!),
              ))
              .get();
      // Evict before deleting URL metadata, so a local failure remains retryable.
      for (final photo in photos) {
        await personPhotos.evict(detailScope, cachedEnrolledPhoto(photo));
      }
      if (person != null) {
        await peoplePhotos.evict(
          owner,
          KnownPerson(
            id: person.id,
            name: person.name,
            relationship: person.relationship,
            status: PeopleFilter.values.byName(person.status),
            updatedAt: person.updatedAt,
            photoUrl: person.photoUrl,
          ),
        );
      }
    }
    await db.transaction(() async {
      if (_disposed || await _patient() == null) return;
      if (c.type == 'face_enrollment' && c.subjectId != null) {
        await (db.update(db.cachedPeople)..where(
              (p) =>
                  p.caregiverId.equals(scope.$1) &
                  p.patientId.equals(scope.$2!) &
                  p.id.equals(c.subjectId!),
            ))
            .write(
              const CachedPeopleCompanion(
                status: Value('archived'),
                photoUrl: Value(null),
                embeddingCount: Value(0),
              ),
            );
        await (db.delete(db.cachedPersonPhotos)..where(
              (p) =>
                  p.caregiverId.equals(scope.$1) &
                  p.patientId.equals(scope.$2!) &
                  p.personId.equals(c.subjectId!),
            ))
            .go();
        await (db.delete(db.personDetailStates)..where(
              (p) =>
                  p.caregiverId.equals(scope.$1) &
                  p.patientId.equals(scope.$2!) &
                  p.personId.equals(c.subjectId!),
            ))
            .go();
      }
      await _cache(c);
    });
  }

  Future<HomePatient> editProfile(PatientProfile draft) async {
    await _manager();
    final receipt = await home.changeProfile(scope.$2!, draft);
    ++_generation;
    return receipt;
  }

  Future<void> cacheProfile(HomePatient receipt) => home.cacheProfile(receipt);

  Future<void> logout({required bool Function() current}) async {
    if (!_logoutAcknowledged) {
      final tokens = await credentials.readCaregiver();
      if (!current()) throw ApiFailure(ApiFailureKind.cancelled);
      if (tokens != null) {
        final response = await client.request<dynamic>(
          '/auth/logout',
          method: 'POST',
          credential: ApiCredential.none,
          data: {'refresh_token': tokens.refreshToken},
          cancelToken: _cancel,
        );
        if (response.statusCode != 204) throw _invalid;
      }
      _logoutAcknowledged = true;
      ++_generation;
    }
    if (!current()) throw ApiFailure(ApiFailureKind.cancelled);
    await credentials.clearCaregiver();
  }

  Stream<MoreData> watch() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.cachedCaregiverAccounts,
          db.cachedConsents,
          db.dashboardPatients,
          db.cachedPlaces,
          db.placesCacheStates,
          db.cachedCaregiverLinks,
          db.caregiversCacheStates,
        },
      )
      .watch()
      .asyncMap((_) => read());
  Future<MoreData> read() => db.transaction(() async {
    final account = await (db.select(
      db.cachedCaregiverAccounts,
    )..where((a) => a.id.equals(scope.$1))).getSingleOrNull();
    final exists = await _patient() != null;
    final rows = exists
        ? await (db.select(db.cachedConsents)..where(_consents)).get()
        : <CachedConsent>[];
    final consents =
        rows.map((r) => _consent(jsonDecode(r.payload) as Map)).toList()
          ..sort((a, b) => b.givenAt.compareTo(a.givenAt));
    final places = exists
        ? await (db.select(db.placesCacheStates)..where(
                (p) =>
                    p.caregiverId.equals(scope.$1) &
                    p.patientId.equals(scope.$2!),
              ))
              .getSingleOrNull()
        : null;
    final count = places == null
        ? null
        : (await (db.select(db.cachedPlaces)..where(
                    (p) =>
                        p.caregiverId.equals(scope.$1) &
                        p.patientId.equals(scope.$2!),
                  ))
                  .get())
              .length;
    final caregivers = exists
        ? await (db.select(db.caregiversCacheStates)..where(
                (c) =>
                    c.caregiverId.equals(scope.$1) &
                    c.patientId.equals(scope.$2!),
              ))
              .getSingleOrNull()
        : null;
    final caregiverCount = caregivers == null
        ? null
        : (await (db.select(db.cachedCaregiverLinks)..where(
                    (c) =>
                        c.caregiverId.equals(scope.$1) &
                        c.patientId.equals(scope.$2!),
                  ))
                  .get())
              .length;
    return MoreData(
      account: account == null
          ? null
          : CaregiverAccount(account.id, account.fullName, account.email),
      consents: consents,
      placeCount: count,
      caregiverCount: caregiverCount,
    );
  });
}
