import 'package:flutter/material.dart';

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
    duration: const Duration(milliseconds: 6200),
  );

  late final AnimationController _buttonsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );

  late final Animation<double> _mapSlideAnimation;
  late final Animation<double> _questSlideAnimation;
  late final Animation<double> _earthSlideAnimation;
  late final Animation<double> _buttonsSlideAnimation;

  static final Cubic _fastStartSlowEnd = Cubic(0.25, 0.1, 0.25, 1.0);

  bool _outroStarted = false;

  @override
  void initState() {
    super.initState();

    _mapSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _introController, curve: _fastStartSlowEnd),
    );

    _questSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _introController, curve: _fastStartSlowEnd),
    );

    _earthSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _introController, curve: _fastStartSlowEnd),
    );

    _buttonsSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: _fastStartSlowEnd),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _introController.forward();
      });
    });

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

    _buttonsController.reverse().then((_) {
      _introController.reverse().then((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/mode-selection');
        }
      });
    });
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
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
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
                      const SizedBox(height: 23),
                      AnimatedBuilder(
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
                              label: 'LARO',
                              highlightColor: const Color(0xFF0C27DA),
                              onTap: _playOutro,
                            ),
                            const SizedBox(height: 6),
                            _HoverButton(
                              label: 'MGA SETTING',
                              highlightColor: const Color(0xFF0C27DA),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _introController,
                    builder: (context, child) {
                      return Positioned.fill(
                        child: Transform.translate(
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
                        ),
                      );
                    },
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
        onTap: widget.onTap,
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