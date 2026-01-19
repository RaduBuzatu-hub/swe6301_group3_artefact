import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDatabaseFactory() {
  final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
  if (!isDesktop) return;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
