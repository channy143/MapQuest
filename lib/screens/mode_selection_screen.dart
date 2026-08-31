import 'dart:ui';

import 'package:flutter/material.dart';

/// The screen shown after the home screen outro, letting the player pick
/// between the two game modes (Learning and Game).
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6200),
  );

  late final AnimationController _cardsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );

  late final Animation<double> _titleLeftAnimation;
  late final Animation<double> _titleRightAnimation;
  late final Animation<double> _cardsAnimation;

  static final Cubic _fastStartSlowEnd = Cubic(0.25, 0.1, 0.25, 1.0);

  bool _outroStarted = false;

  @override
  void initState() {
    super.initState();

    _titleLeftAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _introController, curve: _fastStartSlowEnd),
    );

    _titleRightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _introController, curve: _fastStartSlowEnd),
    );

    _cardsAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardsController, curve: _fastStartSlowEnd),
    );

    _introController.forward();

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cardsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  void _playOutro() {
    if (_outroStarted) return;
    _outroStarted = true;

    _cardsController.reverse().then((_) {
      _introController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final screenWidth = screen.width;
    final screenHeight = screen.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0C27DA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _introController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_titleLeftAnimation.value * screenWidth, 0),
                        child: child,
                      );
                    },
                    child: Text(
                      'PAGPILI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: 130,
                        color: Colors.white,
                        height: 0.7,
                      ),
                    ),
                  ),
                   AnimatedBuilder(
                    animation: _introController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_titleRightAnimation.value * screenWidth, -24),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NG',
                          style: TextStyle(
                            fontFamily: 'Jomhuria',
                            fontSize: 48,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'MODE',
                          style: TextStyle(
                            fontFamily: 'Jolly Lodger',
                            fontSize: 110,
                            color: Colors.white,
                            height: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: screenHeight * 0.42,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _cardsController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _cardsAnimation.value * screenHeight),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.white,
                            Colors.white,
                          ],
                          stops: [0.0, 0.10, 0.16, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeCard(onTap: _playOutro),
                            const SizedBox(height: 24),
                            _ModeCard(onTap: _playOutro),
                            const SizedBox(height: 24),
                            _ModeCard(onTap: _playOutro),
                            const SizedBox(height: 24),
                            _ModeCard(onTap: _playOutro),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A frosted-glass mode card with square (no rounded) corners.
class _ModeCard extends StatefulWidget {
  const _ModeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _hovered ? 14 : 8,
              sigmaY: _hovered ? 14 : 8,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: screen.width * 0.72,
              height: screen.width * 0.72,
              decoration: BoxDecoration(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: _hovered
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}