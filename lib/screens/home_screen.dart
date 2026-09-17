import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/audio_manager.dart';
import '../widgets/drifting_clouds_layer.dart';
import 'mode_selection_screen.dart';

/// The first screen shown when the app opens.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final AnimationController _buttonsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _mapSlideAnimation;
  late final Animation<double> _questSlideAnimation;
  late final Animation<double> _earthSlideAnimation;
  late final Animation<double> _buttonsSlideAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _buttonsFadeAnimation;

  bool _outroStarted = false;

  @override
  void initState() {
    super.initState();

    _mapSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _questSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _earthSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _buttonsSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _buttonsFadeAnimation = CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _introController.forward();

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _buttonsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _introController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  void _playOutro() {
    if (_outroStarted) return;
    _outroStarted = true;

    _buttonsController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _introController.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ModeSelectionScreen(
                  onBack: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const HomeScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        });
      }
    });
  }

  void _openSettingsModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _SettingsModal(),
    );
  }

  void _exitApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C27DA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.biggest.shortestSide;
            final screen = MediaQuery.sizeOf(context);
            final isCompact = screen.shortestSide < 600;
            final earthSize = available + 220 + (isCompact ? 50 : 0);
            final screenWidth = screen.width;
            final screenHeight = screen.height;

            return Stack(
              children: [
                // Clouds drifting in the background (persists into mode selection)
                const Positioned.fill(
                  child: DriftingCloudsLayer(),
                ),

                // Branding Title & Menu Navigation Buttons
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _introController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_mapSlideAnimation.value * screenWidth, 0),
                                  child: child,
                                );
                              },
                              child: Text(
                                'MAP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Jomhuria',
                                  fontSize: 160,
                                  color: Colors.white,
                                  height: 0.6,
                                ),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _introController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_questSlideAnimation.value * screenWidth, 0),
                                  child: child,
                                );
                              },
                              child: Text(
                                'QUEST',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Jolly Lodger',
                                  fontSize: 100,
                                  color: Colors.white,
                                  height: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 23),
                      FadeTransition(
                        opacity: _buttonsFadeAnimation,
                        child: AnimatedBuilder(
                          animation: _buttonsController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _buttonsSlideAnimation.value * screenHeight * 1.0),
                              child: child,
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HoverButton(
                                label: 'MAGLARO',
                                highlightColor: const Color(0xFF0C27DA),
                                onTap: _playOutro,
                              ),
                              const SizedBox(height: 6),
                              _HoverButton(
                                label: 'MGA SETTING',
                                highlightColor: const Color(0xFF0C27DA),
                                onTap: _openSettingsModal,
                              ),
                              const SizedBox(height: 6),
                              _HoverButton(
                                label: 'ISARA ANG APP',
                                highlightColor: const Color(0xFF0C27DA),
                                onTap: _exitApp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Rotating Earth (ALWAYS on top / front z-index)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _introController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 200 + _earthSlideAnimation.value * (screenHeight * 0.5 + earthSize * 0.5)),
                          child: Center(
                            child: Transform.scale(
                              scale: isCompact ? 1.35 : 1.0,
                              child: RotationTransition(
                                turns: _spinController,
                                child: Image.asset(
                                  'assets/images/Earth.png',
                                  width: earthSize,
                                  height: earthSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Ambient Audio Toggle in top-right corner
                Positioned(
                  top: 16,
                  right: 16,
                  child: FadeTransition(
                    opacity: _buttonsFadeAnimation,
                    child: const _AudioToggleButton(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A hoverable menu button that reveals a square background and turns the
/// label text blue (matching the app's home screen background) on hover.
class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.label,
    required this.highlightColor,
    this.onTap,
  });

  final String label;
  final Color highlightColor;
  final VoidCallback? onTap;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Jomhuria',
              fontSize: 34,
              color: _hovered ? widget.highlightColor : Colors.white,
              height: 0.9,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating toggle button for ambient background music.
class _AudioToggleButton extends StatefulWidget {
  const _AudioToggleButton();

  @override
  State<_AudioToggleButton> createState() => _AudioToggleButtonState();
}

class _AudioToggleButtonState extends State<_AudioToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AudioManager.instance.isMutedNotifier,
      builder: (context, isMuted, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              AudioManager.instance.handleUserInteraction();
              AudioManager.instance.toggleMute();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: _isHovered ? 0.8 : 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glassmorphic settings dialog with Music and Sound volume sliders and Mute toggle.
class _SettingsModal extends StatelessWidget {
  const _SettingsModal();

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.shortestSide < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact ? 380 : 440,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 28,
                vertical: isCompact ? 20 : 26,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF07123A).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.70),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MGA SETTING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Jomhuria',
                                fontSize: isCompact ? 38 : 46,
                                color: Colors.amber,
                                height: 0.85,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Ayusin ang lakas ng tugtog at tunog',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        tooltip: 'Isara',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Music Volume Slider Section
                  ValueListenableBuilder<double>(
                    valueListenable: AudioManager.instance.musicVolumeNotifier,
                    builder: (context, musicVol, child) {
                      return _VolumeSliderTile(
                        title: 'TUGTUGIN (MUSIC)',
                        icon: Icons.music_note_rounded,
                        accentColor: Colors.amber,
                        value: musicVol,
                        onChanged: (val) {
                          AudioManager.instance.setMusicVolume(val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Sound Volume Slider Section
                  ValueListenableBuilder<double>(
                    valueListenable: AudioManager.instance.soundVolumeNotifier,
                    builder: (context, soundVol, child) {
                      return _VolumeSliderTile(
                        title: 'TUNOG (SOUND SFX)',
                        icon: Icons.volume_up_rounded,
                        accentColor: const Color(0xFF00E5FF),
                        value: soundVol,
                        onChanged: (val) {
                          AudioManager.instance.setSoundVolume(val);
                        },
                        onChangeEnd: (val) {
                          AudioManager.instance.playClick();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Mute Button
                  ValueListenableBuilder<bool>(
                    valueListenable: AudioManager.instance.isMutedNotifier,
                    builder: (context, isMuted, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AudioManager.instance.playClick();
                            AudioManager.instance.toggleMute();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isMuted ? Colors.redAccent : const Color(0xFF00E676),
                            side: BorderSide(
                              color: isMuted ? Colors.redAccent : const Color(0xFF00E676),
                              width: 1.5,
                            ),
                            backgroundColor: isMuted
                                ? Colors.redAccent.withValues(alpha: 0.12)
                                : const Color(0xFF00E676).withValues(alpha: 0.12),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            size: 22,
                          ),
                          label: Text(
                            isMuted ? 'NAKA-MUTE (I-UNMUTE ANG LAHAT)' : 'MAY TUNOG (I-MUTE ANG LAHAT)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: const Color(0xFF07123A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'ISARA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeSliderTile extends StatelessWidget {
  const _VolumeSliderTile({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: accentColor.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}