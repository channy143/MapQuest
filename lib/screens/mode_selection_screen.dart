import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/classic_question.dart';
import '../services/audio_manager.dart';
import '../widgets/drifting_clouds_layer.dart';
import '../widgets/game_mode_picker_modal.dart';
import 'classic_quiz_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'treasure_hunt_screen.dart';

/// The screen shown after the home screen outro, letting the player pick
/// between the two game modes (Learning and Game).
class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final AnimationController _cardsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final AnimationController _loadingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final Animation<double> _titleLeftAnimation;
  late final Animation<double> _titleRightAnimation;
  late final Animation<double> _cardsAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _cardsFadeAnimation;
  late final Animation<double> _loadingFadeAnimation;
  late final Animation<double> _loadingScaleAnimation;

  bool _outroStarted = false;
  bool _isLoading = false;
  String? _selectedMode;

  @override
  void initState() {
    super.initState();

    _titleLeftAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _titleRightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _cardsAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _titleFadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _cardsFadeAnimation = CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _loadingFadeAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeOut,
    );

    _loadingScaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: Curves.easeOutBack,
      ),
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
    _loadingController.dispose();
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onCardSelected(String modeTitle) {
    if (_outroStarted) return;

    final normalized = modeTitle.toLowerCase();
    if (normalized.contains('laro') || normalized.contains('game')) {
      _showGameModePicker();
    } else {
      _startModeTransition(
        modeName: 'mode ng pagkatuto',
        destinationBuilder: (context) => GameScreen(
          selectedMode: 'mode ng pagkatuto',
          onBack: _returnToModeSelection,
        ),
      );
    }
  }

  Future<void> _showGameModePicker() async {
    final selection = await showGeneralDialog<GameSubModeSelection>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GameModePicker',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, anim1, anim2) {
        return GameModePickerModal(
          onSelectMode: (subMode) {
            Navigator.of(dialogContext).pop(subMode);
          },
          onCancel: () {
            Navigator.of(dialogContext).pop(null);
          },
        );
      },
      transitionBuilder: (dialogContext, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.90, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );

    if (selection == null || !mounted) return;

    switch (selection) {
      case GameSubModeSelection.level:
        _startModeTransition(
          modeName: 'Hanapin ang Lokasyon!',
          destinationBuilder: (context) => GameScreen(
            selectedMode: 'mode ng laro',
            gameSubMode: GameSubMode.level,
            onBack: _returnToModeSelection,
          ),
        );
        break;
      case GameSubModeSelection.hanapinKayamanan:
        _startModeTransition(
          modeName: 'Hanapin ang Kayamanan!',
          destinationBuilder: (context) => TreasureHuntScreen(
            onBack: _returnToModeSelection,
          ),
        );
        break;
      case GameSubModeSelection.subukinKaalaman:
        _startModeTransition(
          modeName: 'Subukin ang Kaalaman!',
          destinationBuilder: (context) => ClassicQuizScreen(
            title: 'SUBUKIN ANG KAALAMAN!',
            subtitle: '14 na Tanong • Araling Panlipunan',
            questions: SubukinKaalamanRegistry.questions,
            showInstructions: true,
            onBack: _returnToModeSelection,
          ),
        );
        break;
      case GameSubModeSelection.classic:
        _startModeTransition(
          modeName: 'Klasikong Pagsusulit',
          destinationBuilder: (context) => ClassicQuizScreen(
            onBack: _returnToModeSelection,
          ),
        );
        break;
      case GameSubModeSelection.coordinates:
        _startModeTransition(
          modeName: 'Coordinate Quest',
          destinationBuilder: (context) => GameScreen(
            selectedMode: 'mode ng laro',
            gameSubMode: GameSubMode.coordinates,
            onBack: _returnToModeSelection,
          ),
        );
        break;
    }
  }

  void _startModeTransition({
    required String modeName,
    required WidgetBuilder destinationBuilder,
  }) {
    if (_outroStarted) return;
    _outroStarted = true;
    _selectedMode = modeName;

    _cardsController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _introController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
            _loadingController.forward();
            Future.delayed(const Duration(milliseconds: 2200), () {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        destinationBuilder(context),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              }
            });
          }
        });
      }
    });
  }

  void _returnToModeSelection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ModeSelectionScreen(onBack: widget.onBack),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _goBackToMenu() {
    if (_outroStarted) return;
    _outroStarted = true;

    _cardsController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _introController.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const HomeScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final screenWidth = screen.width;
    final screenHeight = screen.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToMenu();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0C27DA),
        body: SafeArea(
          child: Stack(
            children: [
              // Drifting clouds background (persists from menu screen)
              const Positioned.fill(
                child: DriftingCloudsLayer(),
              ),
              if (!_isLoading) ...[
              Positioned(
                top: 16,
                left: 16,
                child: FadeTransition(
                  opacity: _introController,
                  child: _BackButton(onTap: _goBackToMenu),
                ),
              ),
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _titleFadeAnimation,
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
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 258,
              bottom: 0,
              child: FadeTransition(
                opacity: _cardsFadeAnimation,
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
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.85, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 240),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeCard(
                              imageAsset: 'assets/images/Firefly.png',
                              title: 'mode ng pagkatuto',
                              description:
                                  'Tuklasin ang Pilipinas at alamin kung nasaan ito sa mundo gamit ang mapa.',
                              onTap: () => _onCardSelected('mode ng pagkatuto'),
                            ),
                            const SizedBox(height: 24),
                            _ModeCard(
                              imageAsset: 'assets/images/Firefly2.png',
                              title: 'mode ng laro',
                              description:
                                  'Sumabak sa mga misyon at gamitin ang iyong kaalaman sa mapa upang maging isang Geography Explorer!',
                              onTap: () => _onCardSelected('mode ng laro'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        if (_isLoading)
            Positioned.fill(
              child: FadeTransition(
                opacity: _loadingFadeAnimation,
                child: _LoadingIndicator(
                  scaleAnimation: _loadingScaleAnimation,
                  spinController: _spinController,
                  pulseController: _pulseController,
                  selectedMode: _selectedMode,
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);
  }
}

/// A frosted-glass mode card with square (no rounded) corners.
class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String imageAsset;
  final String title;
  final String description;
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
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
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
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: _hovered
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedScale(
                      scale: _hovered ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _hovered
                            ? const Color(0xFF071888).withValues(alpha: 0.92)
                            : const Color(0xFF0C27DA).withValues(alpha: 0.85),
                        border: Border(
                          top: BorderSide(
                            color: _hovered
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title.toUpperCase(),
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: 'Jomhuria',
                              fontSize: 38,
                              color: Colors.white,
                              height: 0.9,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.description,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
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

/// A clean arrow-only back button placed on the top-left of the screen.
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _hovered ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// A centered, glowing loading indicator with rotating Earth and pulsing text.
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({
    required this.scaleAnimation,
    required this.spinController,
    required this.pulseController,
    this.selectedMode,
  });

  final Animation<double> scaleAnimation;
  final AnimationController spinController;
  final AnimationController pulseController;
  final String? selectedMode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Glowing outer pulse ring
                AnimatedBuilder(
                  animation: pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withValues(
                              alpha: 0.18 + 0.28 * pulseController.value,
                            ),
                            blurRadius: 28 + 14 * pulseController.value,
                            spreadRadius: 2 + 4 * pulseController.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Rotating outer progress circle
                RotationTransition(
                  turns: spinController,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.95),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Rotating Earth icon in the center
                RotationTransition(
                  turns: spinController,
                  child: Image.asset(
                    'assets/images/Earth.png',
                    width: 74,
                    height: 74,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.65 + 0.35 * pulseController.value,
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'NAGLO-LOAD...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jomhuria',
                      fontSize: 42,
                      color: Colors.white,
                      letterSpacing: 2.5,
                      height: 0.85,
                    ),
                  ),
                  if (selectedMode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedMode!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: 32,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 2,
                        height: 0.85,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}