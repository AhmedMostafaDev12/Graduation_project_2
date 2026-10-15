import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../domain/journal_data.dart';

class JournalPreviewFailure implements Exception {
  const JournalPreviewFailure([this.status]);
  final int? status;
  @override
  String toString() => 'Journal preview unavailable';
}

abstract interface class JournalPreviews {
  Future<Uint8List> load(JournalMedia media);
  void expire(DateTime now);
  void clear();
  void dispose();
}

class NativeJournalPreviews implements JournalPreviews {
  NativeJournalPreviews(this.key, this.clock);
  final JournalKey key;
  final DateTime Function() clock;
  HttpClient? _client;
  final _pending = <String, Future<Uint8List>>{},
      _bytes = <String, Uint8List>{};
  final _expiry = <String, DateTime?>{};
  bool _disposed = false;
  int _generation = 0;
  String _id(JournalMedia p) =>
      '${key.$1.caregiverId}:${key.$1.patientId}:${key.$2}:${p.id}';
  @override
  Future<Uint8List> load(JournalMedia p) {
    if (_disposed || p.previewUrl == null || !p.available(clock())) {
      return Future.error(const JournalPreviewFailure());
    }
    return _pending.putIfAbsent(_id(p), () => _fetch(p, _generation));
  }

  Future<Uint8List> _fetch(JournalMedia p, int generation) async {
    try {
      final uri = Uri.tryParse(p.previewUrl!);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw const JournalPreviewFailure();
      }
      _client ??= HttpClient();
      final request = await _client!.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw JournalPreviewFailure(response.statusCode);
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (_disposed ||
          generation != _generation ||
          !p.available(clock()) ||
          bytes.isEmpty) {
        throw const JournalPreviewFailure();
      }
      _bytes[_id(p)] = bytes;
      _expiry[_id(p)] = p.expiresAt;
      return bytes;
    } on JournalPreviewFailure {
      rethrow;
    } catch (_) {
      throw const JournalPreviewFailure();
    }
  }

  @override
  void expire(DateTime now) {
    for (final id in _expiry.keys.toList()) {
      if (_expiry[id]?.isAfter(now) == false) {
        final bytes = _bytes.remove(id);
        if (bytes != null) {
          PaintingBinding.instance.imageCache.evict(MemoryImage(bytes));
        }
        _pending.remove(id);
        _expiry.remove(id);
      }
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
    _expiry.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
  }
}
