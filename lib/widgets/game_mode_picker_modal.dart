import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/audio_manager.dart';

/// Selection callback options for Game Mode sub-modes.
enum GameSubModeSelection {
  level,
  hanapinKayamanan,
  subukinKaalaman,
  classic,
  coordinates,
}

/// Glassmorphic modal sheet / dialog displaying the 3 game sub-modes.
class GameModePickerModal extends StatelessWidget {
  const GameModePickerModal({
    super.key,
    required this.onSelectMode,
    required this.onCancel,
  });

  final ValueChanged<GameSubModeSelection> onSelectMode;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isCompact = screen.width < 600;
    final maxWidth = screen.width > 700 ? 620.0 : screen.width * 0.94;
    final maxHeight = screen.height * 0.88;

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          color: Colors.white,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 28,
                    isCompact ? 18 : 24,
                    isCompact ? 16 : 28,
                    isCompact ? 16 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF07123A).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.65),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.25),
                        blurRadius: 36,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.60),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row with Close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PUMILI NG LARO!',
                                    style: TextStyle(
                                      fontFamily: 'Jomhuria',
                                      fontSize: isCompact ? 36 : 48,
                                      color: Colors.amber,
                                      height: 0.85,
                                      letterSpacing: 2.0,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Alin ang gusto mong subukan?',
                                    style: TextStyle(
                                      fontSize: isCompact ? 12.5 : 14.0,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      height: 1.3,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                AudioManager.instance.playClick();
                                onCancel();
                              },
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              tooltip: 'Isara',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Option 1: Hanapin ang Lokasyon!
                        _ModeOptionCard(
                          icon: Icons.explore_rounded,
                          accentColor: const Color(0xFF00E5FF),
                          tagText: 'TUKLASIN!',
                          title: 'Hanapin ang Lokasyon!',
                          description:
                              'Pindutin sa mapa ang ibinigay na lugar at tapusin ang 10 misyon!',
                          isCompact: isCompact,
                          onTap: () => onSelectMode(GameSubModeSelection.level),
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Hanapin ang Kayamanan!
                        _ModeOptionCard(
                          icon: Icons.auto_awesome_rounded,
                          accentColor: const Color(0xFFFFB300),
                          tagText: 'BAGONG LARO!',
                          title: 'Hanapin ang Kayamanan!',
                          description:
                              'Sundan ang mga pahiwatig at larawan upang matukoy kung saan nakatago ang kayamanan!',
                          isCompact: isCompact,
                          onTap: () => onSelectMode(GameSubModeSelection.hanapinKayamanan),
                        ),
                        const SizedBox(height: 12),

                        // Option 3: Subukin ang Kaalaman!
                        _ModeOptionCard(
                          icon: Icons.quiz_rounded,
                          accentColor: const Color(0xFF00E676),
                          tagText: '14 NA TANONG!',
                          title: 'Subukin ang Kaalaman!',
                          description:
                              'Subukin ang iyong kaalaman sa heograpiya ng Pilipinas at mga karatig-bansa nang walang mapa!',
                          isCompact: isCompact,
                          onTap: () => onSelectMode(GameSubModeSelection.subukinKaalaman),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatefulWidget {
  const _ModeOptionCard({
    required this.icon,
    required this.accentColor,
    required this.tagText,
    required this.title,
    required this.description,
    required this.isCompact,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String tagText;
  final String title;
  final String description;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  State<_ModeOptionCard> createState() => _ModeOptionCardState();
}

class _ModeOptionCardState extends State<_ModeOptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final isCompact = widget.isCompact;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: _hovered
                ? accent.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? accent : Colors.white.withValues(alpha: 0.25),
              width: _hovered ? 1.6 : 1.2,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.30),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Circle
              Container(
                width: isCompact ? 40 : 48,
                height: isCompact ? 40 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.20),
                  border: Border.all(color: accent.withValues(alpha: 0.60), width: 1.4),
                ),
                child: Icon(
                  widget.icon,
                  color: accent,
                  size: isCompact ? 22 : 26,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),

              // Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withValues(alpha: 0.45), width: 0.8),
                      ),
                      child: Text(
                        widget.tagText,
                        style: TextStyle(
                          fontSize: isCompact ? 9 : 10.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                          letterSpacing: 0.6,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: isCompact ? 11.5 : 13,
                        color: Colors.white.withValues(alpha: 0.80),
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              // Arrow Indicator
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: _hovered ? accent : Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
