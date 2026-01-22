import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'navigation_page/bottom_navigation.dart';
import 'firebase_options.dart';
import 'data/local_db.dart';
import 'data/database_factory_stub.dart'
    if (dart.library.io) 'data/database_factory_io.dart';

/// Application entry point: initialize local DB + Firebase, then run the app.
Future<void> main() async {
  // Firebase needs bindings and initialization before the app runs.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize sqflite FFI on desktop and local storage for profiles/trips.
  initDatabaseFactory();
  await LocalDb.instance.init();
  // Configure Firebase for the current platform.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Root widget configuring theme and bootstrapping BottomNav shell.
/// Defines the app title, Material theme, and first screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4A148C),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel App',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surfaceContainerHighest,
        useMaterial3: true,
      ),
      home: const BottomNav(),
    );
  }
}
