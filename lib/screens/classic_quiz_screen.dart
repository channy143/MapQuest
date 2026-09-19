import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/classic_question.dart';
import '../services/audio_manager.dart';
import '../services/game_progress_storage.dart';
import 'home_screen.dart';
import 'mode_selection_screen.dart';

/// Quiz Screen for Subukin ang Kaalaman! and Classic Quiz.
///
/// Features Grade 4 Araling Panlipunan geography MCQs without a map,
/// tracking points and recording game mode completion.
class ClassicQuizScreen extends StatefulWidget {
  const ClassicQuizScreen({
    super.key,
    this.onBack,
    this.title = 'KLASIKONG PAGSUSULIT',
    this.subtitle,
    this.questions,
    this.showInstructions = false,
  });

  final VoidCallback? onBack;
  final String title;
  final String? subtitle;
  final List<ClassicQuestion>? questions;
  final bool showInstructions;

  @override
  State<ClassicQuizScreen> createState() => _ClassicQuizScreenState();
}

class _ClassicQuizScreenState extends State<ClassicQuizScreen>
    with SingleTickerProviderStateMixin {
  late List<ClassicQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  int _correctCount = 0;
  int _score = 0;
  bool _isQuizCompleted = false;
  late bool _showInstructions;
  bool _newlyEarnedUltimate = false;
  double _fontScale = 1.0; // Cycles: 1.0x -> 1.25x -> 1.5x

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
    _showInstructions = widget.showInstructions;
    _startNewQuiz();
  }

  void _startNewQuiz() {
    setState(() {
      if (widget.questions != null) {
        _questions = widget.questions!
            .map((q) => q.withShuffledOptions())
            .toList();
      } else if (widget.title.contains('SUBUKIN') ||
          widget.title.contains('Kaalaman')) {
        _questions = SubukinKaalamanRegistry.questions
            .map((q) => q.withShuffledOptions())
            .toList();
      } else {
        _questions = ClassicQuestionRegistry.getRandomQuestions(10)
            .map((q) => q.withShuffledOptions())
            .toList();
      }
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _hasAnswered = false;
      _correctCount = 0;
      _score = 0;
      _isQuizCompleted = false;
    });
    _cardAnimController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  void _onOptionSelected(int index) {
    if (_hasAnswered) return;

    final question = _questions[_currentIndex];
    final isCorrect = question.isCorrect(index);

    if (isCorrect) {
      AudioManager.instance.playCorrect();
    } else {
      AudioManager.instance.playWrong();
    }

    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
      if (isCorrect) {
        _correctCount++;
        _score += 10;
      }
    });
  }

  Future<void> _onNextQuestion() async {
    AudioManager.instance.playClick();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _hasAnswered = false;
      });
      _cardAnimController.forward(from: 0.0);
    } else {
      final newlyEarned = await GameProgressStorage.recordGameCompleted(
        GameProgressStorage.gameSubukinKaalaman,
      );
      setState(() {
        _isQuizCompleted = true;
        _newlyEarnedUltimate = newlyEarned;
      });
      if (_correctCount >= (_questions.length * 0.6).round()) {
        AudioManager.instance.playCorrect();
      } else {
        AudioManager.instance.playWrong();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isQuizCompleted) {
          _handleReturnToMenu();
        } else {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF07143F),
        body: Stack(
          children: [
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
              child: SafeArea(
                child: Column(
                  children: [
                    // Top Header Bar
                    _buildHeader(isCompact),

                    // Main Quiz Content / Completed Card
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? 16 : 24,
                            vertical: isCompact ? 3 : 5,
                          ),
                          child: _isQuizCompleted
                              ? _buildCompletionCard(isCompact)
                              : _buildQuestionCard(isCompact),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showInstructions) _buildInstructionOverlay(isCompact),
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
        vertical: isCompact ? 5 : 7,
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
                    padding: const EdgeInsets.all(5),
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
              const SizedBox(width: 10),

              // Title / Mode Tag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Jomhuria',
                        fontSize: isCompact ? 24 : 28,
                        color: Colors.amber,
                        height: 0.85,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      widget.subtitle ??
                          '${_questions.length} Tanong • Araling Panlipunan',
                      style: TextStyle(
                        fontSize: isCompact ? 10.5 : 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Score Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.65),
                    width: 1.2,
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

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(bool isCompact) {
    final question = _questions[_currentIndex];
    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 700 ? 640.0 : screen.width * 0.95;

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
                  horizontal: isCompact ? 14 : 18,
                  vertical: isCompact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF081544).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
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
                    // Question Counter Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.50),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'TANONG ${_currentIndex + 1} NG ${_questions.length}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00E5FF),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            const SizedBox(width: 10),
                            Text(
                              '$_correctCount Tama',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Question Prompt in Clean Light Container
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 9 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        question.prompt,
                        style: TextStyle(
                          fontSize: (isCompact ? 16.5 : 18.5) * _fontScale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.34,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 3 Choices
                    for (int i = 0; i < question.options.length; i++)
                      _buildOptionTile(
                        index: i,
                        optionText: question.options[i],
                        isCompact: isCompact,
                        question: question,
                      ),

                    // Explanation Box (shown after answer)
                    if (_hasAnswered) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 14,
                          vertical: isCompact ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedOptionIndex == question.correctIndex
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedOptionIndex == question.correctIndex
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFFFDE68A),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedOptionIndex == question.correctIndex
                                  ? '🎉 '
                                  : '💡 ',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedOptionIndex == question.correctIndex
                                        ? 'TAMA ANG IYONG SAGOT!'
                                        : 'ALAMIN ANG PALIWANAG:',
                                    style: TextStyle(
                                      fontSize: (isCompact ? 12.0 : 13.0) * _fontScale,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedOptionIndex ==
                                              question.correctIndex
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFFB45309),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.explanation,
                                    style: TextStyle(
                                      fontSize: (isCompact ? 14.5 : 16.5) * _fontScale,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 1.34,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Next / Complete Button
                      SizedBox(
                        height: isCompact ? 38 : 42,
                        child: ElevatedButton(
                          onPressed: () {
                            AudioManager.instance.playClick();
                            _onNextQuestion();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: const Color(0xFF0B1953),
                            elevation: 8,
                            shadowColor: Colors.amber.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _currentIndex < _questions.length - 1
                                ? 'SUSUNOD NA TANONG ➔'
                                : 'TINGNAN ANG RESULTA 🏆',
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
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

  Widget _buildOptionTile({
    required int index,
    required String optionText,
    required bool isCompact,
    required ClassicQuestion question,
  }) {
    Color borderColor = const Color(0xFFCBD5E1);
    Color bgColor = const Color(0xFFFFFFFF);
    Color textColor = Colors.black;
    Widget? trailingIcon;

    if (_hasAnswered) {
      if (index == question.correctIndex) {
        borderColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFDCFCE7);
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF16A34A), size: 22);
      } else if (_selectedOptionIndex == index) {
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
                  _onOptionSelected(index);
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
                    color: _hasAnswered && index == question.correctIndex
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

  Widget _buildCompletionCard(bool isCompact) {
    final percentage = ((_correctCount / _questions.length) * 100).round();
    String badgeTitle = 'EXPLORER NG ASYA';
    String badgeEmoji = '🥉';
    Color badgeColor = Colors.orangeAccent;
    String feedbackMessage =
      'Magpatuloy sa pagsasanay upang higit pang maunawaan ang mapa ng Pilipinas!';

    if (_correctCount >= 9) {
      badgeTitle = 'DALUBHASA SA HEOGRAPIYA';
      badgeEmoji = '🥇';
      badgeColor = Colors.amber;
      feedbackMessage =
          'Kamangha-mangha! Lubos mong kabisado ang lokasyon at katangian ng Pilipinas sa Asya!';
    } else if (_correctCount >= 6) {
      badgeTitle = 'MAHUSAY NA MANLALAKBAY';
      badgeEmoji = '🥈';
      badgeColor = const Color(0xFF00E5FF);
      feedbackMessage =
          'Napakagaling! Malapit mo nang makabisado ang buong mapa at mga karatig-bansa!';
    }

    final screen = MediaQuery.sizeOf(context);
    final maxWidth = screen.width > 600 ? 520.0 : screen.width * 0.94;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 20 : 32),
            decoration: BoxDecoration(
              color: const Color(0xFF081544).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.65),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badgeEmoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text(
                  'TAPOS NA ANG PAGSUSULIT!',
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

                // Badge Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.60), width: 1.2),
                  ),
                  child: Text(
                    badgeTitle,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13.5,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (_newlyEarnedUltimate) ...[
                  const SizedBox(height: 10),
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
                const SizedBox(height: 18),

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

                // Feedback in Light Container with pure black text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    feedbackMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14.5 : 16.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.38,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          _startNewQuiz();
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
                  const Text('🧠📝', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                    ),
                    child: Text(
                      SubukinKaalamanRegistry.instruction,
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
                        _showInstructions = false;
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
                      'SIMULAN ANG PAGSUSULIT 📝',
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
}
