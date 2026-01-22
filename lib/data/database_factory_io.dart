import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initializes the sqflite FFI database factory on desktop platforms.
void initDatabaseFactory() {
  // Only enable the FFI database on desktop targets.
  final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
  if (!isDesktop) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
