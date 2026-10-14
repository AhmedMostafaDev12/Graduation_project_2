import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart';

import '../../../core/db/remori_database.dart';
import '../domain/person_detail.dart';
import '../domain/people_data.dart';

abstract interface class PersonDetailPhotoCache {
  Future<void> evict(PersonDetailScope scope, EnrolledPhoto photo);
}

class NativePersonDetailPhotoCache implements PersonDetailPhotoCache {
  NativePersonDetailPhotoCache() {
    CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
  }
  @override
  Future<void> evict(PersonDetailScope scope, EnrolledPhoto photo) async {
    for (final full in [true, false]) {
      final url = full ? photo.url : photo.thumbnailUrl ?? photo.url;
      final key = photo.key(scope, full: full);
      try {
        await CachedNetworkImage.evictFromCache(url, cacheKey: key);
        await CachedNetworkImageProvider(url, cacheKey: key).evict();
      } catch (_) {
        /* Cache/platform errors never expose signed URLs. */
      }
    }
  }
}

EnrolledPhoto cachedEnrolledPhoto(CachedPersonPhoto photo) => EnrolledPhoto(
  id: photo.id,
  url: photo.url,
  thumbnailUrl: photo.thumbnailUrl,
);

Future<void> purgePersonDetails(
  RemoriDatabase db,
  PeopleScope owner, {
  Set<String>? ids,
  PersonDetailPhotoCache? photoCache,
}) async {
  if (ids != null && ids.isEmpty) return;
  final old =
      await (db.select(db.cachedPersonPhotos)..where(
            (p) =>
                p.caregiverId.equals(owner.caregiverId) &
                p.patientId.equals(owner.patientId) &
                (ids == null ? p.personId.isNotNull() : p.personId.isIn(ids)),
          ))
          .get();
  await db.transaction(() async {
    await (db.delete(db.cachedPersonPhotos)..where(
          (p) =>
              p.caregiverId.equals(owner.caregiverId) &
              p.patientId.equals(owner.patientId) &
              (ids == null ? p.personId.isNotNull() : p.personId.isIn(ids)),
        ))
        .go();
    await (db.delete(db.personDetailStates)..where(
          (p) =>
              p.caregiverId.equals(owner.caregiverId) &
              p.patientId.equals(owner.patientId) &
              (ids == null ? p.personId.isNotNull() : p.personId.isIn(ids)),
        ))
        .go();
  });
  final cache = photoCache ?? NativePersonDetailPhotoCache();
  for (final photo in old) {
    await cache.evict(
      PersonDetailScope(owner, photo.personId),
      cachedEnrolledPhoto(photo),
    );
  }
}
