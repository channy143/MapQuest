import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/mode_selection_screen.dart';

/// The root widget of the GeoQuest Philippines app.
///
/// This is where the app-wide theme and the starting screen are defined.
class GeoQuestApp extends StatelessWidget {
  const GeoQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoQuest Philippines',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routes: {
        '/mode-selection': (context) => const ModeSelectionScreen(),
      },
      home: const HomeScreen(),
    );
  }
}
