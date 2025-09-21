import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Simplified Logo for Favicon and Small Icons
class SimpleLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const SimpleLogo({
    super.key,
    this.size = 32.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: SimpleLogoPainter(
        color: color ?? Theme.of(context).primaryColor,
      ),
    );
  }
}

/// Simple Logo Painter for small sizes and favicons
class SimpleLogoPainter extends CustomPainter {
  final Color color;

  SimpleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, bgPaint);

    // Microphone shape in white
    final micPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final micRadius = radius * 0.25;
    final micHeight = radius * 0.5;

    // Microphone capsule
    final micRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius * 0.1),
        width: micRadius * 2,
        height: micHeight,
      ),
      Radius.circular(micRadius),
    );
    
    canvas.drawRRect(micRect, micPaint);

    // Sound waves
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    // Right side waves
    for (int i = 0; i < 2; i++) {
      final waveRadius = radius * (0.4 + i * 0.15);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: waveRadius),
        -math.pi / 6,
        math.pi / 3,
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(SimpleLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Logo for different contexts
class ContextualLogo {
  /// App bar logo - small and clean
  static Widget appBar({double size = 32}) {
    return const SimpleLogo(size: 32, color: Color(0xFF6C63FF));
  }

  /// Favicon - very simple for web
  static Widget favicon({double size = 16}) {
    return const SimpleLogo(size: 16, color: Color(0xFF6C63FF));
  }

  /// Notification icon
  static Widget notification({double size = 24}) {
    return const SimpleLogo(size: 24, color: Color(0xFF6C63FF));
  }

  /// Loading placeholder
  static Widget placeholder({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: const SimpleLogo(size: 24, color: Color(0xFF6C63FF)),
    );
  }
}
