import 'dart:async';
import 'package:flutter/material.dart';

import '../services/audio_manager.dart';
import '../services/coordinate_quest_storage.dart';
import '../widgets/drifting_clouds_layer.dart';
import 'home_screen.dart';

/// Intro splash art and asset loading screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    // Progress bar animation (loads smoothly over ~2.4 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    // Pulse animation for loading text & glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Subtle Earth rotation animation
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _startLoadingProcess();
  }

  Future<void> _startLoadingProcess() async {
    // Kick off animation
    _progressController.forward();

    // Preload storage and audio service in parallel
    unawaited(CoordinateQuestStorage.getUnlockedLocations());
    unawaited(AudioManager.instance.startBackgroundMusic());

    // Once progress completes, navigate smoothly into HomeScreen
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache primary images
    precacheImage(const AssetImage('assets/images/Earth.png'), context);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.shortestSide < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0C27DA),
      body: Stack(
        children: [
          // Background ambient drifting clouds layer
          const Positioned.fill(
            child: DriftingCloudsLayer(),
          ),

          // Deep radial glow backdrop
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF1939E8).withValues(alpha: 0.6),
                    const Color(0xFF07123A).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          // Centered Splash Art & Loading Content
          Center(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Intro Splash Art: Spinning Earth with glowing aura
                    Container(
                      width: isCompact ? 130 : 160,
                      height: isCompact ? 130 : 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.45),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: RotationTransition(
                        turns: _spinController,
                        child: Image.asset(
                          'assets/images/Earth.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // MapQuest Branding Typography
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'MAP',
                          style: TextStyle(
                            fontFamily: 'Jomhuria',
                            fontSize: isCompact ? 72 : 90,
                            color: Colors.white,
                            height: 0.8,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'QUEST',
                          style: TextStyle(
                            fontFamily: 'Jolly Lodger',
                            fontSize: isCompact ? 48 : 60,
                            color: Colors.amber,
                            height: 0.8,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Loading Prompt Text
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07123A).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Please w8....loading core assets',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.6,
                            shadows: [
                              Shadow(
                                color: Colors.amber.withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Centered Vertical Progress Bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final progress = _progressAnimation.value;
                        final percentInt = (progress * 100).toInt();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // The Vertical Progress Bar Track & Fill
                            Container(
                              width: isCompact ? 18 : 22,
                              height: isCompact ? 130 : 160,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.6,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Progress fill from bottom to top
                                    FractionallySizedBox(
                                      heightFactor: progress.clamp(0.0, 1.0),
                                      widthFactor: 1.0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Color(0xFF00E5FF),
                                              Color(0xFFFFD54F),
                                              Color(0xFFFF9100),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFFFFD54F),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Percentage Label below the vertical bar
                            Text(
                              '$percentInt%',
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
