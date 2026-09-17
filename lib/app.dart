import 'dart:ui';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/audio_manager.dart';

/// Custom scroll behavior that enables drag-scrolling with touch, mouse, and stylus.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

/// The root widget of the GeoQuest Philippines app.
///
/// This is where the app-wide theme and the starting screen are defined.
class GeoQuestApp extends StatefulWidget {
  const GeoQuestApp({super.key});

  @override
  State<GeoQuestApp> createState() => _GeoQuestAppState();
}

class _GeoQuestAppState extends State<GeoQuestApp> {
  @override
  void initState() {
    super.initState();
    // Start ambient background music on app launch
    AudioManager.instance.startBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // On Web, audio autoplay may require a user gesture.
      // Any first tap or click seamlessly triggers audio playback.
      onPointerDown: (_) => AudioManager.instance.handleUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp(
        title: 'MapQuest',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
