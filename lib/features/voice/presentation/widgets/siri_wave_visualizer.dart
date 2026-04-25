import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SiriWaveVisualizer extends StatefulWidget {
  final double soundLevel; // Value between 0.0 and 1.0

  const SiriWaveVisualizer({super.key, required this.soundLevel});

  @override
  State<SiriWaveVisualizer> createState() => _SiriWaveVisualizerState();
}

class _SiriWaveVisualizerState extends State<SiriWaveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous phase scroller with a fast, fluid speed
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
          painter: _SiriWavePainter(
            phase: _controller.value * 2 * math.pi,
            soundLevel: widget.soundLevel,
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 100, // Fixed bounding box for the visualizer
          ),
        );
      },
    );
  }
}

class _SiriWavePainter extends CustomPainter {
  final double phase;
  final double soundLevel;

  _SiriWavePainter({required this.phase, required this.soundLevel});

  @override
  void paint(Canvas canvas, Size size) {
    // Base hum (silence) vs Max speaking amplitude
    final double restingAmplitude = size.height * 0.1;
    final double spokenAmplitude = size.height * 0.8; 
    
    // Dynamically smooth interpolation based on active voice volume
    double targetAmplitude = (restingAmplitude + (soundLevel * spokenAmplitude)).clamp(restingAmplitude, spokenAmplitude);

    // Primary bright cyan tracking beam
    _drawWave(
      canvas,
      size,
      amplitude: targetAmplitude,
      frequency: 2.5, // Wavelength
      phaseOffset: phase, // Forward motion
      opacity: 1.0,
      strokeWidth: 2.5,
    );
    
    // Secondary deep purple entangled beam
    _drawWave(
      canvas,
      size,
      amplitude: targetAmplitude * 0.7,
      frequency: 3.5, 
      phaseOffset: phase * 1.5 + math.pi / 2, // Off-sync motion
      opacity: 0.6,
      strokeWidth: 1.8,
    );

    // Tertiary magenta background echo beam
    _drawWave(
      canvas,
      size,
      amplitude: targetAmplitude * 0.45,
      frequency: 4.5,
      phaseOffset: phase * -1.2 + math.pi, // Counter-rotational sweep
      opacity: 0.35,
      strokeWidth: 1.2,
    );
  }

  void _drawWave(
    Canvas canvas, 
    Size size, 
    {
      required double amplitude, 
      required double frequency, 
      required double phaseOffset, 
      required double opacity, 
      required double strokeWidth
    }) 
  {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final halfHeight = size.height / 2;

    for (double i = 0; i <= size.width; i++) {
      // Normalize 'x' horizontally from -1 to 1
      final x = (i / size.width) * 2 - 1; 
      
      // Calculate inverse polynomial attenuation (pinches the wave at the exact borders)
      final attenuation = math.pow(4.0 / (4.0 + math.pow(x * 4.0, 4.0)), 4.0);
      
      // Standard mathematical Sine
      final rawY = math.sin((i / size.width) * math.pi * frequency + phaseOffset);
      
      // Applied height output
      final y = rawY * amplitude * attenuation;

      if (i == 0) {
        path.moveTo(i, halfHeight + y);
      } else {
        path.lineTo(i, halfHeight + y);
      }
    }
    
    // The Cinematic Fintech Gradient (Cyan -> Violet -> Magenta)
    paint.shader = ui.Gradient.linear(
      Offset(0, halfHeight),
      Offset(size.width, halfHeight),
      [
        const Color(0xFF00E5FF).withOpacity(0.0), // Faded Cyan Edge
        const Color(0xFF00E5FF).withOpacity(opacity), // Cyan Core
        const Color(0xFF651FFF).withOpacity(opacity), // Violet Junction
        const Color(0xFFFF007F).withOpacity(opacity), // Magenta Core
        const Color(0xFFFF007F).withOpacity(0.0), // Faded Magenta Edge
      ],
      [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SiriWavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.soundLevel != soundLevel;
  }
}
