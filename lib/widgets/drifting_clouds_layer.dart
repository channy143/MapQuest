import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Specifications for an individual drifting cloud.
class CloudData {
  final double initialProgress;
  final int loopsPerCycle;
  final double yFraction;
  final double width;
  final double bobAmplitude;
  final double bobSpeed;
  final double bobPhase;
  final bool flipX;

  const CloudData({
    required this.initialProgress,
    required this.loopsPerCycle,
    required this.yFraction,
    required this.width,
    this.bobAmplitude = 6.0,
    this.bobSpeed = 2.0,
    this.bobPhase = 0.0,
    this.flipX = false,
  });
}

/// A balanced set of drifting clouds (100% solid opacity).
const List<CloudData> defaultClouds = [
  CloudData(
    initialProgress: 0.05,
    loopsPerCycle: 2,
    yFraction: 0.08,
    width: 160,
    bobAmplitude: 5.0,
    bobSpeed: 1.8,
    bobPhase: 0.4,
    flipX: false,
  ),
  CloudData(
    initialProgress: 0.65,
    loopsPerCycle: 1,
    yFraction: 0.16,
    width: 210,
    bobAmplitude: 7.0,
    bobSpeed: 1.2,
    bobPhase: 1.5,
    flipX: true,
  ),
  CloudData(
    initialProgress: 0.35,
    loopsPerCycle: 2,
    yFraction: 0.28,
    width: 140,
    bobAmplitude: 6.0,
    bobSpeed: 2.2,
    bobPhase: 2.1,
    flipX: false,
  ),
  CloudData(
    initialProgress: 0.85,
    loopsPerCycle: 2,
    yFraction: 0.42,
    width: 180,
    bobAmplitude: 6.5,
    bobSpeed: 1.9,
    bobPhase: 3.5,
    flipX: true,
  ),
  CloudData(
    initialProgress: 0.20,
    loopsPerCycle: 1,
    yFraction: 0.58,
    width: 230,
    bobAmplitude: 8.0,
    bobSpeed: 1.3,
    bobPhase: 4.8,
    flipX: false,
  ),
  CloudData(
    initialProgress: 0.55,
    loopsPerCycle: 2,
    yFraction: 0.72,
    width: 190,
    bobAmplitude: 6.0,
    bobSpeed: 2.0,
    bobPhase: 0.9,
    flipX: true,
  ),
];

/// A layer of clouds that smoothly drifts from left to right across the screen.
/// Persists across menu and mode selection screens without fading out.
class DriftingCloudsLayer extends StatefulWidget {
  const DriftingCloudsLayer({
    super.key,
    this.clouds = defaultClouds,
  });

  final List<CloudData> clouds;

  @override
  State<DriftingCloudsLayer> createState() => _DriftingCloudsLayerState();
}

class _DriftingCloudsLayerState extends State<DriftingCloudsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cloudController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _cloudController,
            builder: (context, _) {
              final t = _cloudController.value;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final cloud in widget.clouds)
                    _buildSingleCloud(cloud, t, screenWidth, screenHeight),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSingleCloud(
    CloudData cloud,
    double t,
    double screenWidth,
    double screenHeight,
  ) {
    // Seamless left-to-right drift with integer cycle multiplier
    final progress = (cloud.initialProgress + t * cloud.loopsPerCycle) % 1.0;
    final totalDistance = screenWidth + cloud.width;
    final x = -cloud.width + progress * totalDistance;

    // Gentle vertical bobbing
    final bob = math.sin(t * 2 * math.pi * cloud.bobSpeed + cloud.bobPhase) *
        cloud.bobAmplitude;
    final y = (screenHeight * cloud.yFraction) + bob;

    // 100% solid opacity with no transparency
    return Positioned(
      left: x,
      top: y,
      child: Transform.scale(
        scaleX: cloud.flipX ? -1.0 : 1.0,
        child: Image.asset(
          'assets/images/clouds',
          width: cloud.width,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/clouds.png',
              width: cloud.width,
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}
