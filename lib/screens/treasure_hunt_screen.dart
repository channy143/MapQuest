import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/treasure_hunt_question.dart';
import '../services/audio_manager.dart';
import '../services/game_progress_storage.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';

/// Screen for the "Hanapin ang Kayamanan!" game mode.
///
/// Features 10 visual treasure hunt clues (pictures from assets/images/treasure_hunt/),
/// a mix of multiple choice and text typing input, Grade 4 AP geography clues,
/// and awards the "Map Detective" badge upon completion.
class TreasureHuntScreen extends StatefulWidget {
  const TreasureHuntScreen({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with SingleTickerProviderStateMixin {
  late final List<TreasureHuntQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  String? _submittedText;
  bool _hasAnswered = false;
  bool _isAnswerCorrect = false;
  int _correctCount = 0;
  int _score = 0;
  bool _isCompleted = false;
  bool _showInstructionModal = true;
  bool _newlyEarnedUltimate = false;
  double _fontScale = 1.0; // 1.0x -> 1.25x -> 1.5x

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _cardAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _cardFadeAnim = CurvedAnimation(
    parent: _cardAnimController,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _cardSlideAnim = Tween<Offset>(
    begin: const Offset(0.0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _cardAnimController,
    curve: Curves.easeOutCubic,
  ));

  @override
  void initState() {
    super.initState();
    _questions = TreasureHuntRegistry.questions;
    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cycleFontScale() {
    AudioManager.instance.playClick();
    setState(() {
      if (_fontScale == 1.0) {
        _fontScale = 1.25;
      } else if (_fontScale == 1.25) {
        _fontScale = 1.5;
      } else {
        _fontScale = 1.0;
      }
    });
  }

  void _submitChoice(int index) {
    if (_hasAnswered) return;

    final question = _questions[_currentIndex];
    final selectedAnswer = question.options[index];
    final isCorrect = question.isAnswerCorrect(selectedAnswer);

    if (isCorrect) {
      AudioManager.instance.playCorrect();
    } else {
      AudioManager.instance.playWrong();
    }

    setState(() {
      _selectedOptionIndex = index;
      _submittedText = selectedAnswer;
      _hasAnswered = true;
      _isAnswerCorrect = isCorrect;
      if (isCorrect) {
        _correctCount++;
        _score += 15;
      }
    });
  }

  void _submitTypedAnswer() {
    if (_hasAnswered) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final question = _questions[_currentIndex];
    final isCorrect = question.isAnswerCorrect(text);

    if (isCorrect) {
      AudioManager.instance.playCorrect();
    } else {
      AudioManager.instance.playWrong();
    }

    setState(() {
      _submittedText = text;
      _hasAnswered = true;
      _isAnswerCorrect = isCorrect;
      // Match option index if typed text matches one of the options
      for (int i = 0; i < question.options.length; i++) {
        if (question.options[i].toLowerCase() == text.toLowerCase()) {
          _selectedOptionIndex = i;
          break;
        }
      }
      if (isCorrect) {
        _correctCount++;
        _score += 15;
      }
    });
  }

  Future<void> _onNextQuestion() async {
    AudioManager.instance.playClick();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _submittedText = null;
        _hasAnswered = false;
        _isAnswerCorrect = false;
        _textController.clear();
      });
      _cardAnimController.forward(from: 0.0);
    } else {
      // Finished all 10 questions!
      final newlyEarnedUltimate = await GameProgressStorage.recordGameCompleted(
        GameProgressStorage.gameHanapinKayamanan,
      );

      setState(() {
        _isCompleted = true;
        _newlyEarnedUltimate = newlyEarnedUltimate;
      });

      if (_correctCount >= 6) {
        AudioManager.instance.playCorrect();
      } else {
        AudioManager.instance.playWrong();
      }
    }
  }

  void _restartGame() {
    setState(() {
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _submittedText = null;
      _hasAnswered = false;
      _isAnswerCorrect = false;
      _correctCount = 0;
      _score = 0;
      _isCompleted = false;
      _textController.clear();
    });
    _cardAnimController.forward(from: 0.0);
  }

  void _handleBack() {
    if (widget.onBack != null) {
      try {
        widget.onBack!();
        return;
      } catch (_) {}
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ModeSelectionScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _handleReturnToMenu() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  void _showImagePreviewDialog(String imageAsset) {
    AudioManager.instance.playClick();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'I-tap kahit saan para isara',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isCompleted) {
          _handleReturnToMenu();
        } else {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07143F),
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0C27DA),
                    Color(0xFF07164C),
                    Color(0xFF030D2A),
                  ],
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(isCompact),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 24,
                          vertical: isCompact ? 4 : 8,
                        ),
                        child: _isCompleted
                            ? _buildCompletionCard(isCompact)
                            : _buildQuestionCard(isCompact),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Welcome Instructions Modal Overlay
            if (_showInstructionModal)
              _buildInstructionOverlay(isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final progress = (_currentIndex + 1) / _questions.length;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: isCompact ? 6 : 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Back Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    AudioManager.instance.playClick();
                    _handleBack();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title Header
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HANAPIN ANG KAYAMANAN!',
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: isCompact ? 28 : 34,
                        color: Colors.amber,
                        height: 0.85,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Gamitin ang mga pahiwatig at larawan',
                      style: TextStyle(
                        fontSize: isCompact ? 10.5 : 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),

              // Score Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.50),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(bool isCompact) {
    final question = _questions[_currentIndex];
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 700 ? 640.0 : screen.width * 0.96;

    return SlideTransition(
      position: _cardSlideAnim,
      child: FadeTransition(
        opacity: _cardFadeAnim,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 20,
                  vertical: isCompact ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF081544).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.50),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Counter and Font Scale Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.50),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'KATANUNGAN ${_currentIndex + 1} NG ${_questions.length}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _cycleFontScale,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.format_size_rounded,
                                    size: 15,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(_fontScale * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Clue Image Container with Golden Border
                    GestureDetector(
                      onTap: () => _showImagePreviewDialog(question.imageAsset),
                      child: Container(
                        height: isCompact ? 160 : 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.70),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.20),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                question.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported_rounded,
                                        color: Colors.white54, size: 40),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in_rounded,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'I-zoom',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 12),

                    // Prompt Box (High Contrast Light Background with Black Text)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 14 : 18,
                        vertical: isCompact ? 12 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        question.prompt,
                        style: TextStyle(
                          fontSize: (isCompact ? 16.0 : 18.0) * _fontScale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Answer Input Section (Typing or Choice Selection)
                    if (question.isTypingQuestion && !_hasAnswered) ...[
                      _buildTypingInput(isCompact),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'O maaari ring pumili sa mga sumusunod:',
                          style: TextStyle(
                            fontSize: 12.0 * _fontScale,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    // Multiple Choice Options
                    ...List.generate(
                      question.options.length,
                      (index) => _buildOptionTile(
                        index: index,
                        optionText: question.options[index],
                        isCompact: isCompact,
                        question: question,
                      ),
                    ),

                    // Feedback and Explanation Card after answering
                    if (_hasAnswered) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isAnswerCorrect
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isAnswerCorrect
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isAnswerCorrect
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: _isAnswerCorrect
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isAnswerCorrect
                                        ? 'TAMA ANG IYONG SAGOT! (+15 PUNTOS)'
                                        : 'MALI! Ang tamang sagot ay: ${question.correctAnswer}',
                                    style: TextStyle(
                                      fontSize: 13 * _fontScale,
                                      fontWeight: FontWeight.bold,
                                      color: _isAnswerCorrect
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.explanation,
                              style: TextStyle(
                                fontSize: 13.0 * _fontScale,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Next Button
                      ElevatedButton(
                        onPressed: _onNextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF081544),
                          padding: EdgeInsets.symmetric(
                            vertical: isCompact ? 12 : 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                        child: Text(
                          _currentIndex < _questions.length - 1
                              ? 'SUSUNOD NA PAHIWATIG ➔'
                              : 'TINGNAN ANG RESULTA 🏆',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingInput(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.amber,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontSize: (isCompact ? 15.0 : 17.0) * _fontScale,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'I-type ang sagot dito...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: (isCompact ? 14.0 : 16.0) * _fontScale,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _submitTypedAnswer(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AudioManager.instance.playClick();
              _submitTypedAnswer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF081544),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Isumite',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String optionText,
    required bool isCompact,
    required TreasureHuntQuestion question,
  }) {
    Color borderColor = const Color(0xFFCBD5E1);
    Color bgColor = const Color(0xFFFFFFFF);
    Color textColor = Colors.black;
    Widget? trailingIcon;

    if (_hasAnswered) {
      final isOptionCorrect = question.isAnswerCorrect(optionText);
      final isOptionSelected = _selectedOptionIndex == index ||
          (_submittedText != null &&
              question.options[index].toLowerCase() ==
                  _submittedText!.trim().toLowerCase());

      if (isOptionCorrect) {
        borderColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFDCFCE7);
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF16A34A), size: 22);
      } else if (isOptionSelected) {
        borderColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: Color(0xFFDC2626), size: 22);
      } else {
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF64748B);
      }
    }

    final letter = String.fromCharCode(65 + index); // A, B, C

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _hasAnswered
              ? null
              : () {
                  AudioManager.instance.playClick();
                  _submitChoice(index);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 10 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _hasAnswered && question.isAnswerCorrect(optionText)
                        ? const Color(0xFF16A34A)
                        : (_hasAnswered && _selectedOptionIndex == index
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0F172A)),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      fontSize: (isCompact ? 15.5 : 17.5) * _fontScale,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionOverlay(bool isCompact) {
    return Container(
      color: Colors.black.withValues(alpha: 0.80),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: EdgeInsets.all(isCompact ? 20 : 28),
              decoration: BoxDecoration(
                color: const Color(0xFF081544).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amber,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.35),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🗺️💎', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 6),
                  Text(
                    'HANAPIN ANG KAYAMANAN!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Jomhuria',
                      fontSize: isCompact ? 36 : 46,
                      color: Colors.amber,
                      height: 0.85,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Instruction Container in High-Contrast Light Background
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: Text(
                      TreasureHuntRegistry.modeInstruction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCompact ? 14.5 : 16.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      AudioManager.instance.playClick();
                      setState(() {
                        _showInstructionModal = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: const Color(0xFF081544),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                    ),
                    child: Text(
                      'SIMULAN ANG PAGHAHANAP 🧭',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
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

  Widget _buildCompletionCard(bool isCompact) {
    final percentage = ((_correctCount / _questions.length) * 100).round();
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 600 ? 540.0 : screen.width * 0.94;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 20 : 30),
            decoration: BoxDecoration(
              color: const Color(0xFF081544).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.75),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.30),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💎🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text(
                  'NAHANAP ANG KAYAMANAN!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Jomhuria',
                    fontSize: isCompact ? 36 : 46,
                    color: Colors.amber,
                    height: 0.85,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                // Badge Container: Map Detective (Name only, no description)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Map Detective',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amberAccent,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),

                // If Ultimate Explorer was newly unlocked, celebrate it!
                if (_newlyEarnedUltimate) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Ultimate Explorer',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00E5FF),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Score Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol('TAMANG SAGOT', '$_correctCount / ${_questions.length}', Colors.white),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _buildStatCol('KABUUANG PUNTOS', '$_score', Colors.amberAccent),
                    Container(width: 1, height: 36, color: Colors.white24),
                    _buildStatCol('BAHAGDAN', '$percentage%', const Color(0xFF00E5FF)),
                  ],
                ),
                const SizedBox(height: 18),

                // Feedback
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  ),
                  child: Text(
                    _correctCount >= 8
                        ? 'Napakagaling, Map Detective! Matagumpay mong natuklasan ang lahat ng lokasyon ng kayamanan!'
                        : 'Magaling na pagsisikap! Magpatuloy sa pagsasanay upang maging ganap na dalubhasa sa mapa!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14.0 : 15.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          _restartGame();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54, width: 1.4),
                          padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'MAGLARO MULI',
                          style: TextStyle(
                            fontSize: isCompact ? 12.5 : 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          _handleReturnToMenu();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: const Color(0xFF081544),
                          padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                        ),
                        child: Text(
                          'BUMALIK SA MENU',
                          style: TextStyle(
                            fontSize: isCompact ? 12.5 : 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
