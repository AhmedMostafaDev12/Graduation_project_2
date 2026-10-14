import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import '../domain/people_data.dart';

abstract interface class PeoplePhotoCache {
  Future<void> evict(PeopleScope scope, KnownPerson person);
}

class NativePeoplePhotoCache implements PeoplePhotoCache {
  NativePeoplePhotoCache() {
    CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
  }
  @override
  Future<void> evict(PeopleScope scope, KnownPerson person) async {
    final url = person.photoUrl;
    if (url == null) return;
    final key = person.imageKey(scope);
    await CachedNetworkImage.evictFromCache(url, cacheKey: key);
    // evictFromCache's memory provider uses the URL; also remove the ID-keyed entry.
    await CachedNetworkImageProvider(url, cacheKey: key).evict();
  }
}

/// Native cached_network_image's HTTP exception message (verified in its source).
/// Inspect only the status message, never stringify/log its signed URL.
bool isExpiredPeoplePhoto(Object error) =>
    error is HttpException && error.message == 'Invalid statusCode: 403';
