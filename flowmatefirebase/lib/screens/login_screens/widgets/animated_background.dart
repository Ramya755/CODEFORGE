// lib/widgets/animated_background.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // Define colors to match the theme
    const Color primaryPurple = Color(0xFF8A2BE2);
    const Color darkBackgroundColor = Color(0xFF0a0a14);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            // Updated gradient to match the splash screen's ambiance
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                primaryPurple,
                darkBackgroundColor,
              ],
              stops: [0.0, 0.8], // Makes the purple a subtle, centered glow
            ),
          ),
        ),
        Positioned.fill(
          child: LoopAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 25),
            builder: (context, value, child) {
              return CustomPaint(
                foregroundPainter: FloatingParticlesPainter(animationValue: value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  FloatingParticlesPainter({required this.animationValue})
      : particles = List.generate(50, (index) {
          final random = Random(index);
          // Updated particle colors to be a mix of blue and purple
          final particleColor =
              random.nextBool() ? const Color(0xFF00BFFF) : const Color(0xFF8A2BE2);
          return Particle(
            color: particleColor.withOpacity(random.nextDouble() * 0.5 + 0.2),
            size: random.nextDouble() * 2.5 + 1,
            startX: random.nextDouble(),
            startY: random.nextDouble(),
          );
        });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final progress = (animationValue + particle.startY) % 1.0;
      final currentY = progress * size.height;
      final driftX = sin(progress * 2 * pi) * 25;
      final currentX = particle.startX * size.width + driftX;

      final paint = Paint()..color = particle.color;
      canvas.drawCircle(Offset(currentX, currentY), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final Color color;
  final double size;
  final double startX;
  final double startY;

  Particle({
    required this.color,
    required this.size,
    required this.startX,
    required this.startY,
  });
}