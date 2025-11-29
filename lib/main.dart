import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'navigation_page/bottom_navigation.dart';
import 'firebase_options.dart';
import 'data/local_db.dart';

Future<void> main() async {
  // Firebase needs bindings and initialization before the app runs.
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.instance.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// Root widget configuring theme and bootstrapping BottomNav shell.
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
