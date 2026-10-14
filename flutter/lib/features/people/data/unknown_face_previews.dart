import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../domain/people_data.dart';
import '../domain/unknown_faces_data.dart';

class UnknownPreviewFailure implements Exception {
  const UnknownPreviewFailure([this.status]);
  final int? status;
  @override
  String toString() => 'Unknown face preview unavailable';
}

abstract interface class UnknownFacePreviews {
  Future<Uint8List> load(UnknownFace face);
  void clear();
  void dispose();
}

/// Signed images use a bare HTTP client, never caregiver credentials, disk
/// caching, or URL-based image cache keys. Values live only in this screen session.
class NativeUnknownFacePreviews implements UnknownFacePreviews {
  NativeUnknownFacePreviews(this.scope);
  final PeopleScope scope;
  HttpClient? _client;
  final _pending = <String, Future<Uint8List>>{};
  final _bytes = <String, Uint8List>{};
  int _generation = 0;
  bool _disposed = false;
  String _key(UnknownFace face) =>
      '${scope.caregiverId}:${scope.patientId}:${face.id}:${face.sampleId}';
  @override
  Future<Uint8List> load(UnknownFace face) {
    if (_disposed || face.previewUrl == null || face.sampleId == null) {
      return Future.error(const UnknownPreviewFailure());
    }
    return _pending.putIfAbsent(_key(face), () => _fetch(face, _generation));
  }

  Future<Uint8List> _fetch(UnknownFace face, int generation) async {
    try {
      final uri = Uri.tryParse(face.previewUrl!);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const UnknownPreviewFailure();
      }
      _client ??= HttpClient();
      final request = await _client!.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw UnknownPreviewFailure(response.statusCode);
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (_disposed || generation != _generation || bytes.isEmpty) {
        throw const UnknownPreviewFailure();
      }
      _bytes[_key(face)] = bytes;
      return bytes;
    } on UnknownPreviewFailure {
      rethrow;
    } catch (_) {
      throw const UnknownPreviewFailure();
    }
  }

  @override
  void clear() {
    ++_generation;
    _client?.close(force: true);
    _client = null;
    for (final bytes in _bytes.values) {
      PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
    }
    _bytes.clear();
    _pending.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
  }
}
