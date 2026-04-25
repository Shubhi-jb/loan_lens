import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:loan_lens/core/theme/app_theme.dart';

class AmbientParticleAura extends StatefulWidget {
  const AmbientParticleAura({super.key});

  @override
  State<AmbientParticleAura> createState() => _AmbientParticleAuraState();
}

class _AmbientParticleAuraState extends State<AmbientParticleAura> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true); // Slow breathing
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AuraPainter(_controller.value),
          size: Size.infinite,
        );
      }
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double breathValue;
  
  _AuraPainter(this.breathValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    
    // Smooth easing for the breath
    final double easedBreath = Curves.easeInOutSine.transform(breathValue);
    
    // Dynamic radius that expands and contracts
    final double radius = 1.2 + (0.3 * easedBreath);

    // 1. Draw the Ambient LED Core (Under-glow)
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.2), // Anchored at bottom
        radius: radius,
        colors: [
          AppTheme.googleBlue.withOpacity(0.20 + (0.05 * easedBreath)), // Breathing deep core
          const Color(0xFF651FFF).withOpacity(0.10 + (0.05 * easedBreath)), // Violet blend
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(_AuraPainter oldDelegate) => oldDelegate.breathValue != breathValue;
}
