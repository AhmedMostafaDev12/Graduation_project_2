import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'remori_database.dart';

/// Lazy open keeps startup independent of disk work until a repository needs it.
/// Production SQLite lives in the app's private support directory, not temp.
final databaseProvider = Provider<RemoriDatabase>((ref) {
  final database = RemoriDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File.fromUri(directory.uri.resolve('remori.sqlite')),
        logStatements: false,
      );
    }),
  );
  ref.onDispose(database.close);
  return database;
});
