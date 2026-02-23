import 'package:flutter/material.dart';

// ============================================================
// Single Control Button
// ============================================================
class ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLarge;

  const ControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isLarge ? 72.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  onTap != null ? color.withOpacity(0.15) : Colors.transparent,
              border: Border.all(
                color: onTap != null ? color : color.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: onTap != null ? color : color.withOpacity(0.3),
              size: isLarge ? 36 : 28,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: onTap != null
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.2),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Control Buttons Row
// ============================================================
class ControlButtons extends StatelessWidget {
  final bool isRunning;
  final bool canSkipBreak;
  final Color stateColor;
  final VoidCallback onReset;
  final VoidCallback onStartPause;
  final VoidCallback? onSkip;

  const ControlButtons({
    super.key,
    required this.isRunning,
    required this.canSkipBreak,
    required this.stateColor,
    required this.onReset,
    required this.onStartPause,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reset
          ControlButton(
            icon: Icons.replay_rounded,
            //label: 'リセット',
            label: 'Reset',
            color: const Color(0xFF95A5A6),
            onTap: onReset,
          ),
          // Start / Pause
          ControlButton(
            icon: isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            //label: isRunning ? '一時停止' : 'スタート',
            label: isRunning ? 'Pause' : 'Start',
            color: stateColor,
            onTap: onStartPause,
            isLarge: true,
          ),
          // Skip Break
          ControlButton(
            icon: Icons.skip_next_rounded,
            //label: 'スキップ',
            label: 'Skip',
            color: canSkipBreak
                ? const Color(0xFFF39C12)
                : const Color(0xFF95A5A6).withOpacity(0.3),
            onTap: canSkipBreak ? onSkip : null,
          ),
        ],
      ),
    );
  }
}
