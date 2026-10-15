import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../domain/patient_journal_data.dart';

class PatientJournalPreviewFailure implements Exception {
  const PatientJournalPreviewFailure([this.status]);
  final int? status;
  @override
  String toString() => 'Journal preview unavailable';
}

abstract interface class PatientJournalPreviews {
  Future<Uint8List> load(JournalMedia media);
  void expire(DateTime now);
  void clear();
  void dispose();
}

class NativePatientJournalPreviews implements PatientJournalPreviews {
  NativePatientJournalPreviews(this.key, this.clock);
  final PatientJournalKey key;
  final DateTime Function() clock;
  HttpClient? _client;
  final _pending = <String, Future<Uint8List>>{},
      _bytes = <String, Uint8List>{};
  final _expiry = <String, DateTime?>{};
  final _timers = <String, Timer>{};
  bool _disposed = false;
  int _generation = 0;
  String _id(JournalMedia p) =>
      '${key.$1.$1}:${key.$1.$2}:${key.$2}:${key.$3}:${p.id}';
  @override
  Future<Uint8List> load(JournalMedia p) {
    if (_disposed || p.previewUrl == null || !p.available(clock())) {
      return Future.error(const PatientJournalPreviewFailure());
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
        throw const PatientJournalPreviewFailure();
      }
      _client ??= HttpClient();
      final request = await _client!.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw PatientJournalPreviewFailure(response.statusCode);
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      if (_disposed ||
          generation != _generation ||
          !p.available(clock()) ||
          bytes.isEmpty) {
        throw const PatientJournalPreviewFailure();
      }
      _bytes[_id(p)] = bytes;
      _expiry[_id(p)] = p.expiresAt;
      final expiry = p.expiresAt;
      if (expiry != null) {
        _timers.remove(_id(p))?.cancel();
        _timers[_id(p)] = Timer(
          expiry.difference(clock()),
          () => expire(expiry),
        );
      }
      return bytes;
    } on PatientJournalPreviewFailure {
      rethrow;
    } catch (_) {
      throw const PatientJournalPreviewFailure();
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
        _timers.remove(id)?.cancel();
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
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
  }
}
