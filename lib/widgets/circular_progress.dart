import 'dart:math';
import 'package:flutter/material.dart';

// ============================================================
// Circular Progress Painter
// ============================================================
class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircularTimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect at the tip
    if (progress > 0.01) {
      final tipAngle = -pi / 2 + sweepAngle;
      final tipX = center.dx + radius * cos(tipAngle);
      final tipY = center.dy + radius * sin(tipAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

// ============================================================
// Circular Progress Widget
// ============================================================
class CircularProgress extends StatelessWidget {
  final double progress;
  final Color color;
  final String formattedTime;
  final int completedSets;
  final int setsPerRound;
  final Animation<double> pulseAnimation;

  const CircularProgress({
    super.key,
    required this.progress,
    required this.color,
    required this.formattedTime,
    required this.completedSets,
    required this.setsPerRound,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: pulseAnimation,
        child: SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: CircularTimerPainter(
              progress: progress,
              color: color,
              backgroundColor: Colors.white.withOpacity(0.08),
              strokeWidth: 12,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Set Counter dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(setsPerRound, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < completedSets
                                ? color
                                : Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: color.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    //'セット $completedSets / $setsPerRound',
                    'Set $completedSets / $setsPerRound',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
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
